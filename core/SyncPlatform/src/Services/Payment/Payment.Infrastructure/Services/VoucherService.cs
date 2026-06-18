using Microsoft.EntityFrameworkCore;
using Payment.Application.DTOs;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public class VoucherService : IVoucherService
{
    private readonly PaymentDbContext _db;

    public VoucherService(PaymentDbContext db) => _db = db;

    public async Task<IReadOnlyList<VoucherAvailableItemDto>> GetAvailableAsync(
        Guid userId,
        decimal orderAmount,
        Guid? partnerId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        var owned = await _db.UserVouchers
            .AsNoTracking()
            .Include(uv => uv.PromotionCampaign)
            .Where(uv => uv.UserId == userId && !uv.IsUsed)
            .ToListAsync(cancellationToken);

        var publicCampaigns = await _db.PromotionCampaigns
            .AsNoTracking()
            .Where(p => p.IsActive && p.StartsAt <= now && p.EndsAt >= now && p.CouponCode != null)
            .ToListAsync(cancellationToken);

        var items = new List<VoucherAvailableItemDto>();

        foreach (var uv in owned)
        {
            var item = BuildItem(uv.PromotionCampaign, orderAmount, partnerId, userId, uv.Id, now);
            items.Add(item);
        }

        var ownedCampaignIds = owned.Select(x => x.PromotionCampaignId).ToHashSet();
        foreach (var campaign in publicCampaigns.Where(c => !ownedCampaignIds.Contains(c.Id)))
        {
            items.Add(BuildItem(campaign, orderAmount, partnerId, userId, null, now));
        }

        return items
            .OrderByDescending(i => i.Eligible)
            .ThenByDescending(i => i.EstimatedDiscount)
            .ToList();
    }

    public Task<ValidateVoucherResponseDto> ValidateAsync(
        Guid userId,
        ValidateVoucherRequestDto request,
        CancellationToken cancellationToken = default) =>
        ValidateInternalAsync(userId, request, cancellationToken);

    public async Task<ValidateVoucherResponseDto> ValidateInternalAsync(
        Guid userId,
        ValidateVoucherRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            return new ValidateVoucherResponseDto { Valid = false, Message = "Vui lòng nhập mã voucher." };
        }

        var code = request.Code.Trim().ToUpperInvariant();
        var now = DateTimeOffset.UtcNow;

        var campaign = await _db.PromotionCampaigns
            .FirstOrDefaultAsync(p => p.CouponCode == code, cancellationToken);

        if (campaign == null)
            return new ValidateVoucherResponseDto { Valid = false, Message = "Mã voucher không tồn tại." };

        var userVoucher = await _db.UserVouchers
            .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.PromotionCampaignId == campaign.Id && !uv.IsUsed, cancellationToken);

        var eligibility = Evaluate(campaign, request.OrderAmount, request.PartnerId, userId, userVoucher?.Id, now);
        if (!eligibility.Eligible)
        {
            return new ValidateVoucherResponseDto
            {
                Valid = false,
                CampaignId = campaign.Id,
                Message = eligibility.IneligibleReason,
            };
        }

        var discount = CalculateDiscount(campaign, request.OrderAmount);
        return new ValidateVoucherResponseDto
        {
            Valid = true,
            DiscountAmount = discount,
            VoucherId = userVoucher?.Id,
            CampaignId = campaign.Id,
            Message = "Voucher hợp lệ.",
        };
    }

    public async Task MarkUsedAsync(
        Guid userId,
        string code,
        Guid orderId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(code))
            return;

        var normalized = code.Trim().ToUpperInvariant();
        var campaign = await _db.PromotionCampaigns
            .FirstOrDefaultAsync(p => p.CouponCode == normalized, cancellationToken);
        if (campaign == null)
            return;

        campaign.UsageCount += 1;
        campaign.UpdatedAt = DateTimeOffset.UtcNow;

        var userVoucher = await _db.UserVouchers
            .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.PromotionCampaignId == campaign.Id && !uv.IsUsed, cancellationToken);

        if (userVoucher != null)
        {
            userVoucher.IsUsed = true;
            userVoucher.UsedAt = DateTimeOffset.UtcNow;
            userVoucher.UsedOnOrderId = orderId;
            userVoucher.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await _db.SaveChangesAsync(cancellationToken);
    }

    private static VoucherAvailableItemDto BuildItem(
        PromotionCampaign campaign,
        decimal orderAmount,
        Guid? partnerId,
        Guid userId,
        Guid? userVoucherId,
        DateTimeOffset now)
    {
        var eligibility = Evaluate(campaign, orderAmount, partnerId, userId, userVoucherId, now);
        var estimated = eligibility.Eligible ? CalculateDiscount(campaign, orderAmount) : 0m;

        return new VoucherAvailableItemDto
        {
            Code = campaign.CouponCode ?? string.Empty,
            Title = campaign.Name,
            Description = campaign.Description ?? campaign.Name,
            DiscountType = campaign.PromotionType == PromotionType.PercentageDiscount ? "%" : "fixed",
            DiscountValue = campaign.Value,
            MinOrderAmount = campaign.MinimumSpend,
            MaxDiscount = campaign.MaxDiscountAmount,
            ValidUntil = campaign.EndsAt,
            EstimatedDiscount = estimated,
            Eligible = eligibility.Eligible,
            IneligibleReason = eligibility.IneligibleReason,
            CampaignId = campaign.Id,
            UserVoucherId = userVoucherId,
        };
    }

    private static (bool Eligible, string? IneligibleReason) Evaluate(
        PromotionCampaign campaign,
        decimal orderAmount,
        Guid? partnerId,
        Guid userId,
        Guid? userVoucherId,
        DateTimeOffset now)
    {
        if (!campaign.IsActive || campaign.StartsAt > now || campaign.EndsAt < now)
            return (false, "Voucher đã hết hạn.");

        if (campaign.PartnerId.HasValue && partnerId.HasValue && campaign.PartnerId != partnerId)
            return (false, "Voucher không áp dụng cho nhà hàng này.");

        if (campaign.UsageLimit > 0 && campaign.UsageCount >= campaign.UsageLimit)
            return (false, "Voucher đã hết lượt sử dụng.");

        if (orderAmount < campaign.MinimumSpend)
            return (false, $"Đơn tối thiểu {campaign.MinimumSpend:N0}đ.");

        if (campaign.PromotionType is not (PromotionType.PercentageDiscount or PromotionType.FixedDiscount))
            return (false, "Loại voucher không hỗ trợ cho đơn hàng.");

        _ = userId;
        _ = userVoucherId;
        return (true, null);
    }

    private static decimal CalculateDiscount(PromotionCampaign campaign, decimal orderAmount)
    {
        decimal discount = campaign.PromotionType switch
        {
            PromotionType.PercentageDiscount => Math.Round(orderAmount * campaign.Value / 100m, 0, MidpointRounding.AwayFromZero),
            PromotionType.FixedDiscount => campaign.Value,
            _ => 0m,
        };

        if (campaign.MaxDiscountAmount.HasValue)
            discount = Math.Min(discount, campaign.MaxDiscountAmount.Value);

        return Math.Min(discount, orderAmount);
    }
}
