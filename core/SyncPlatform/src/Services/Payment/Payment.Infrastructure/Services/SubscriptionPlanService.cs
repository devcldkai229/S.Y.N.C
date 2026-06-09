using Microsoft.EntityFrameworkCore;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Mappers;
using Payment.Application.Services;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public class SubscriptionPlanService : ISubscriptionPlanService
{
    private readonly PaymentDbContext _db;

    public SubscriptionPlanService(PaymentDbContext db)
    {
        _db = db;
    }

    public async Task<IEnumerable<SubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default)
    {
        var plans = await _db.SubscriptionPlans
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.MonthlyPrice)
            .ToListAsync(cancellationToken);

        return plans.Select(p => p.ToDto());
    }

    public async Task<IEnumerable<SubscriptionPlanDto>> GetAllPlansAsync(
        bool includeInactive = true,
        bool includeDeleted = false,
        CancellationToken cancellationToken = default)
    {
        IQueryable<SubscriptionPlan> query = _db.SubscriptionPlans;

        if (includeDeleted)
        {
            query = query.IgnoreQueryFilters();
        }

        if (!includeInactive)
        {
            query = query.Where(p => p.IsActive);
        }

        var plans = await query
            .AsNoTracking()
            .OrderBy(p => p.MonthlyPrice)
            .ToListAsync(cancellationToken);

        return plans.Select(p => p.ToDto());
    }

    public async Task<SubscriptionPlanDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _db.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(SubscriptionPlan), id);

        return plan.ToDto();
    }

    public async Task<SubscriptionPlanDto> CreateAsync(CreateSubscriptionPlanDto dto, CancellationToken cancellationToken = default)
    {
        var exists = await _db.SubscriptionPlans
            .AnyAsync(p => p.Name.ToLower() == dto.Name.ToLower(), cancellationToken);
        if (exists)
        {
            throw new ConflictException($"Subscription plan with name '{dto.Name}' already exists.");
        }

        var entity = dto.ToEntity();
        
        _db.SubscriptionPlans.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto();
    }

    public async Task<SubscriptionPlanDto> UpdateAsync(Guid id, UpdateSubscriptionPlanDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _db.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(SubscriptionPlan), id);

        var exists = await _db.SubscriptionPlans
            .AnyAsync(p => p.Id != id && p.Name.ToLower() == dto.Name.ToLower(), cancellationToken);
        if (exists)
        {
            throw new ConflictException($"Another subscription plan with name '{dto.Name}' already exists.");
        }

        dto.UpdateEntity(entity);
        
        _db.SubscriptionPlans.Update(entity);
        await _db.SaveChangesAsync(cancellationToken);

        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default)
    {
        var entity = await _db.SubscriptionPlans
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(SubscriptionPlan), id);

        if (softDelete)
        {
            if (entity.DeletedAt != null)
            {
                throw new BadRequestException("Subscription plan is already soft-deleted.");
            }
            entity.DeletedAt = DateTimeOffset.UtcNow;
            _db.SubscriptionPlans.Update(entity);
        }
        else
        {
            _db.SubscriptionPlans.Remove(entity);
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
