using Payment.Application.DTOs;
using Payment.Domain.Enums;

namespace Payment.Application.Services;

public interface IUserSubscriptionService
{
    Task<IEnumerable<UserSubscriptionDto>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserSubscriptionDto?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserSubscriptionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<UserSubscriptionDto>> GetAllSubscriptionsAsync(Guid? userId, SubscriptionStatus? status, bool includeDeleted = true, CancellationToken cancellationToken = default);
    Task<UserSubscriptionDto> CreateAsync(CreateUserSubscriptionDto dto, CancellationToken cancellationToken = default);
    Task<UserSubscriptionDto> UpdateAsync(Guid id, UpdateUserSubscriptionDto dto, CancellationToken cancellationToken = default);
    Task<UserSubscriptionDto> CancelSubscriptionAsync(Guid id, CancelSubscriptionRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default);
}
