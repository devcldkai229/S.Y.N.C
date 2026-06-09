using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface ISubscriptionPlanService
{
    Task<IEnumerable<SubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<SubscriptionPlanDto>> GetAllPlansAsync(bool includeInactive = true, bool includeDeleted = false, CancellationToken cancellationToken = default);
    Task<SubscriptionPlanDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SubscriptionPlanDto> CreateAsync(CreateSubscriptionPlanDto dto, CancellationToken cancellationToken = default);
    Task<SubscriptionPlanDto> UpdateAsync(Guid id, UpdateSubscriptionPlanDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default);
}
