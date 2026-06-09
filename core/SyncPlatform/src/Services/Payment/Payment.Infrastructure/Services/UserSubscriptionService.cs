using Microsoft.EntityFrameworkCore;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Mappers;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public class UserSubscriptionService : IUserSubscriptionService
{
    private readonly PaymentDbContext _db;

    public UserSubscriptionService(PaymentDbContext db)
    {
        _db = db;
    }

    public async Task<IEnumerable<UserSubscriptionDto>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var query = from sub in _db.UserSubscriptions.Where(s => s.UserId == userId)
                    join plan in _db.SubscriptionPlans on sub.SubscriptionPlanId equals plan.Id into planGroup
                    from plan in planGroup.DefaultIfEmpty()
                    orderby sub.StartedAt descending
                    select new { sub, PlanName = plan != null ? plan.Name : "Unknown Plan" };

        var results = await query.ToListAsync(cancellationToken);
        return results.Select(r => r.sub.ToDto(r.PlanName));
    }

    public async Task<UserSubscriptionDto?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;

        // Active = còn hạn (Active chưa expire) hoặc Cancelled nhưng chưa tới ExpiredAt
        // (theo policy: huỷ giữ quyền Premium tới hết hạn)
        var query = from sub in _db.UserSubscriptions.Where(s =>
                        s.UserId == userId &&
                        (
                            (s.Status == SubscriptionStatus.Active && (s.ExpiredAt == null || s.ExpiredAt > now)) ||
                            (s.Status == SubscriptionStatus.Cancelled && s.ExpiredAt != null && s.ExpiredAt > now)
                        ))
                    join plan in _db.SubscriptionPlans on sub.SubscriptionPlanId equals plan.Id into planGroup
                    from plan in planGroup.DefaultIfEmpty()
                    orderby sub.StartedAt descending
                    select new { sub, PlanName = plan != null ? plan.Name : "Unknown Plan" };

        var result = await query.FirstOrDefaultAsync(cancellationToken);
        return result?.sub.ToDto(result.PlanName);
    }

    public async Task<UserSubscriptionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var query = from sub in _db.UserSubscriptions.Where(s => s.Id == id)
                    join plan in _db.SubscriptionPlans on sub.SubscriptionPlanId equals plan.Id into planGroup
                    from plan in planGroup.DefaultIfEmpty()
                    select new { sub, PlanName = plan != null ? plan.Name : "Unknown Plan" };

        var result = await query.FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException(nameof(UserSubscription), id);

        return result.sub.ToDto(result.PlanName);
    }

    public async Task<IEnumerable<UserSubscriptionDto>> GetAllSubscriptionsAsync(
        Guid? userId,
        SubscriptionStatus? status,
        bool includeDeleted = true,
        CancellationToken cancellationToken = default)
    {
        IQueryable<UserSubscription> subQuery = _db.UserSubscriptions;

        if (includeDeleted)
        {
            subQuery = subQuery.IgnoreQueryFilters();
        }

        if (userId.HasValue && userId.Value != Guid.Empty)
        {
            subQuery = subQuery.Where(s => s.UserId == userId.Value);
        }

        if (status.HasValue)
        {
            subQuery = subQuery.Where(s => s.Status == status.Value);
        }

        // We also want to support loading plans even if the plan itself was soft-deleted
        IQueryable<SubscriptionPlan> planQuery = _db.SubscriptionPlans.IgnoreQueryFilters();

        var query = from sub in subQuery
                    join plan in planQuery on sub.SubscriptionPlanId equals plan.Id into planGroup
                    from plan in planGroup.DefaultIfEmpty()
                    orderby sub.CreatedAt descending
                    select new { sub, PlanName = plan != null ? plan.Name : "Unknown Plan" };

        var results = await query.ToListAsync(cancellationToken);
        return results.Select(r => r.sub.ToDto(r.PlanName));
    }

    public async Task<UserSubscriptionDto> CreateAsync(CreateUserSubscriptionDto dto, CancellationToken cancellationToken = default)
    {
        // 1. Verify plan exists
        var plan = await _db.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == dto.SubscriptionPlanId, cancellationToken)
            ?? throw new NotFoundException(nameof(SubscriptionPlan), dto.SubscriptionPlanId);

        // 2. If the user already has an active subscription, deactivate/cancel it to avoid duplicates
        var activeSub = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.UserId == dto.UserId && s.Status == SubscriptionStatus.Active, cancellationToken);
        if (activeSub != null)
        {
            activeSub.Status = SubscriptionStatus.Cancelled;
            activeSub.AutoRenew = false;
            activeSub.UpdatedAt = DateTimeOffset.UtcNow;
            _db.UserSubscriptions.Update(activeSub);
        }

        // 3. Create new subscription
        var entity = dto.ToEntity();
        if (entity.ExpiredAt == null)
        {
            // Default to monthly if not specified
            entity.ExpiredAt = entity.StartedAt.AddDays(30);
        }
        
        _db.UserSubscriptions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto(plan.Name);
    }

    public async Task<UserSubscriptionDto> UpdateAsync(Guid id, UpdateUserSubscriptionDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserSubscription), id);

        var plan = await _db.SubscriptionPlans
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == entity.SubscriptionPlanId, cancellationToken);

        dto.UpdateEntity(entity);

        _db.UserSubscriptions.Update(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto(plan?.Name ?? "Unknown Plan");
    }

    public async Task<UserSubscriptionDto> CancelSubscriptionAsync(Guid id, CancelSubscriptionRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserSubscription), id);

        if (entity.Status != SubscriptionStatus.Active)
        {
            throw new BadRequestException("Only active subscriptions can be cancelled.");
        }

        var plan = await _db.SubscriptionPlans
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == entity.SubscriptionPlanId, cancellationToken);

        // Policy: giữ quyền Premium tới ExpiredAt, KHÔNG hạ tier ngay.
        // Tier sẽ bị hạ về Free khi SubscriptionExpiryJob xử lý lúc ExpiredAt qua.
        entity.Status             = SubscriptionStatus.Cancelled;
        entity.AutoRenew          = false;
        entity.CancellationReason = request.CancellationReason;
        entity.UpdatedAt          = DateTimeOffset.UtcNow;
        // ExpiredAt giữ nguyên — không xoá

        _db.UserSubscriptions.Update(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto(plan?.Name ?? "Unknown Plan");
    }

    public async Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default)
    {
        var entity = await _db.UserSubscriptions
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserSubscription), id);

        if (softDelete)
        {
            if (entity.DeletedAt != null)
            {
                throw new BadRequestException("User subscription is already soft-deleted.");
            }
            entity.DeletedAt = DateTimeOffset.UtcNow;
            _db.UserSubscriptions.Update(entity);
        }
        else
        {
            _db.UserSubscriptions.Remove(entity);
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
