using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;

namespace Marketplace.Domain.Repositories;

public interface IFoodMenuItemRepository : IGenericRepository<FoodMenuItem>
{
    Task<IReadOnlyList<FoodMenuItem>> GetByPartnerIdAsync(
        Guid partnerId,
        AvailabilityStatus? availability = null,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<FoodMenuItem> Items, int TotalRecords)> SearchPagedAsync(
        FoodMenuItemSearchCriteria criteria,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<FoodMenuItem>> GetRandomAsync(
        FoodMenuItemSearchCriteria criteria,
        int count,
        CancellationToken cancellationToken = default);

    Task UpdateRatingAsync(Guid id, decimal ratingAverage, int ratingCount, CancellationToken cancellationToken = default);
}
