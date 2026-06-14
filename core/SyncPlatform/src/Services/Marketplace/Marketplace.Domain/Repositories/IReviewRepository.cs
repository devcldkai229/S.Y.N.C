using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;

namespace Marketplace.Domain.Repositories;

public interface IReviewRepository : IGenericRepository<Review>
{
    Task<(IReadOnlyList<Review> Items, int TotalRecords)> GetByTargetPagedAsync(
        ReviewTargetType targetType,
        Guid targetId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<Review> Items, int TotalRecords)> GetByPartnerScopedAsync(
        Guid partnerId,
        IReadOnlyList<Guid> foodMenuItemIds,
        IReadOnlyList<Guid> affiliateProductIds,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<Review?> GetByUserTargetOrderAsync(
        Guid userId,
        ReviewTargetType targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default);
}
