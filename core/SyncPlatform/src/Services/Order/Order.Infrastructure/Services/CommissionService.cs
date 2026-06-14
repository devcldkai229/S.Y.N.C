using Microsoft.EntityFrameworkCore;
using Order.Application.Clients;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Application.Mappers;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Domain.Models;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public class CommissionService : ICommissionService
{
    private readonly OrderDbContext _db;
    private readonly IMarketplaceClient _marketplaceClient;

    public CommissionService(OrderDbContext db, IMarketplaceClient marketplaceClient)
    {
        _db = db;
        _marketplaceClient = marketplaceClient;
    }

    public async Task CreateFoodDeliveryCommissionAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        if (await _db.CommissionRecords.AnyAsync(
                x => x.Source == CommissionSource.FoodDelivery && x.OrderId == orderId,
                cancellationToken))
            return;

        var order = await _db.Orders.AsNoTracking().FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Models.Order), orderId);

        var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken);
        var rate = partner?.CommissionRate ?? 15m;
        var gross = order.SubtotalAmount;
        var commissionAmount = Math.Round(gross * rate / 100m, 4);

        _db.CommissionRecords.Add(new CommissionRecord
        {
            Source = CommissionSource.FoodDelivery,
            OrderId = order.Id,
            PartnerId = order.PartnerId,
            GrossAmount = gross,
            CommissionRate = rate,
            CommissionAmount = commissionAmount,
            Status = CommissionStatus.Confirmed,
            ConfirmedAt = DateTimeOffset.UtcNow,
        });

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> ReconcileAffiliateAsync(
        AffiliateReconcileRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Lines.Count == 0)
            throw new BadRequestException("At least one reconcile line is required.");

        var created = 0;
        foreach (var line in request.Lines)
        {
            if (string.IsNullOrWhiteSpace(line.ExternalReferenceId))
                continue;

            var exists = await _db.CommissionRecords.AnyAsync(
                x => x.ExternalReferenceId == line.ExternalReferenceId,
                cancellationToken);
            if (exists)
                continue;

            _db.CommissionRecords.Add(new CommissionRecord
            {
                Source = CommissionSource.Affiliate,
                PartnerId = line.PartnerId,
                RelatedProductId = line.RelatedProductId,
                ClickToken = line.ClickToken,
                ExternalReferenceId = line.ExternalReferenceId,
                GrossAmount = line.GrossAmount,
                CommissionRate = line.CommissionRate,
                CommissionAmount = line.CommissionAmount,
                Status = CommissionStatus.Confirmed,
                ConfirmedAt = DateTimeOffset.UtcNow,
            });
            created++;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return created;
    }

    public async Task<(IReadOnlyList<CommissionRecordDto> Items, PaginationMetadata Pagination)> ListAsync(
        CommissionListRequest request,
        CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, request.PageNumber);
        var size = Math.Clamp(request.PageSize, 1, 100);
        var query = _db.CommissionRecords.AsNoTracking().AsQueryable();

        if (request.Source.HasValue)
            query = query.Where(x => x.Source == request.Source.Value);
        if (request.PartnerId.HasValue)
            query = query.Where(x => x.PartnerId == request.PartnerId.Value);
        if (request.Status.HasValue)
            query = query.Where(x => x.Status == request.Status.Value);
        if (request.From.HasValue)
            query = query.Where(x => x.CreatedAt >= request.From.Value);
        if (request.To.HasValue)
            query = query.Where(x => x.CreatedAt <= request.To.Value);

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * size).Take(size).ToListAsync(cancellationToken);
        return (items.Select(x => x.ToDto()).ToList(), new PaginationMetadata(page, size, total));
    }

    public async Task<CommissionRevenueSummaryDto> GetRevenueSummaryAsync(
        CommissionListRequest request,
        CancellationToken cancellationToken = default)
    {
        var query = _db.CommissionRecords.AsNoTracking().AsQueryable();
        if (request.Source.HasValue)
            query = query.Where(x => x.Source == request.Source.Value);
        if (request.PartnerId.HasValue)
            query = query.Where(x => x.PartnerId == request.PartnerId.Value);
        if (request.Status.HasValue)
            query = query.Where(x => x.Status == request.Status.Value);
        if (request.From.HasValue)
            query = query.Where(x => x.CreatedAt >= request.From.Value);
        if (request.To.HasValue)
            query = query.Where(x => x.CreatedAt <= request.To.Value);

        var records = await query.ToListAsync(cancellationToken);
        return new CommissionRevenueSummaryDto
        {
            TotalGross = records.Sum(x => x.GrossAmount),
            TotalCommission = records.Sum(x => x.CommissionAmount),
            RecordCount = records.Count,
        };
    }

    public async Task<CommissionRecordDto> MarkPaidAsync(
        Guid id,
        MarkCommissionPaidDto dto,
        CancellationToken cancellationToken = default)
    {
        var record = await _db.CommissionRecords.FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(CommissionRecord), id);

        record.Status = CommissionStatus.Paid;
        record.PaidAt = dto.PaidAt ?? DateTimeOffset.UtcNow;
        record.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return record.ToDto();
    }
}
