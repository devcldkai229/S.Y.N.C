using Microsoft.EntityFrameworkCore;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Mappers;
using Payment.Application.Services;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public class PromotionCampaignService : IPromotionCampaignService
{
    private readonly PaymentDbContext _db;

    public PromotionCampaignService(PaymentDbContext db)
    {
        _db = db;
    }

    public async Task<IEnumerable<PromotionCampaignDto>> GetActiveCampaignsAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        var campaigns = await _db.PromotionCampaigns
            .AsNoTracking()
            .Where(p => p.IsActive && p.StartsAt <= now && p.EndsAt >= now)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(cancellationToken);

        return campaigns.Select(p => p.ToDto());
    }

    public async Task<IEnumerable<PromotionCampaignDto>> GetAllCampaignsAsync(
        bool includeInactive = true,
        bool includeDeleted = true,
        CancellationToken cancellationToken = default)
    {
        IQueryable<PromotionCampaign> query = _db.PromotionCampaigns;

        if (includeDeleted)
        {
            query = query.IgnoreQueryFilters();
        }

        if (!includeInactive)
        {
            var now = DateTimeOffset.UtcNow;
            query = query.Where(p => p.IsActive && p.StartsAt <= now && p.EndsAt >= now);
        }

        var campaigns = await query
            .AsNoTracking()
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(cancellationToken);

        return campaigns.Select(p => p.ToDto());
    }

    public async Task<PromotionCampaignDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var campaign = await _db.PromotionCampaigns
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(PromotionCampaign), id);

        return campaign.ToDto();
    }

    public async Task<PromotionCampaignDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            throw new BadRequestException("Coupon code cannot be empty.");
        }

        var codeUpper = code.Trim().ToUpper();
        var now = DateTimeOffset.UtcNow;

        var campaign = await _db.PromotionCampaigns
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.CouponCode == codeUpper && p.IsActive && p.StartsAt <= now && p.EndsAt >= now, cancellationToken)
            ?? throw new NotFoundException($"Active promotion campaign with code '{codeUpper}' was not found.");

        return campaign.ToDto();
    }

    public async Task<PromotionCampaignDto> CreateAsync(CreatePromotionCampaignDto dto, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(dto.CouponCode))
        {
            var codeUpper = dto.CouponCode.Trim().ToUpper();
            var exists = await _db.PromotionCampaigns
                .IgnoreQueryFilters()
                .AnyAsync(p => p.CouponCode == codeUpper, cancellationToken);
            if (exists)
            {
                throw new ConflictException($"Coupon code '{codeUpper}' is already in use by another campaign.");
            }
        }

        var entity = dto.ToEntity();
        
        _db.PromotionCampaigns.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto();
    }

    public async Task<PromotionCampaignDto> UpdateAsync(Guid id, UpdatePromotionCampaignDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _db.PromotionCampaigns
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(PromotionCampaign), id);

        if (!string.IsNullOrWhiteSpace(dto.CouponCode))
        {
            var codeUpper = dto.CouponCode.Trim().ToUpper();
            var exists = await _db.PromotionCampaigns
                .IgnoreQueryFilters()
                .AnyAsync(p => p.Id != id && p.CouponCode == codeUpper, cancellationToken);
            if (exists)
            {
                throw new ConflictException($"Coupon code '{codeUpper}' is already in use by another campaign.");
            }
        }

        dto.UpdateEntity(entity);
        
        _db.PromotionCampaigns.Update(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default)
    {
        var entity = await _db.PromotionCampaigns
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(PromotionCampaign), id);

        if (softDelete)
        {
            if (entity.DeletedAt != null)
            {
                throw new BadRequestException("Promotion campaign is already soft-deleted.");
            }
            entity.DeletedAt = DateTimeOffset.UtcNow;
            _db.PromotionCampaigns.Update(entity);
        }
        else
        {
            _db.PromotionCampaigns.Remove(entity);
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
