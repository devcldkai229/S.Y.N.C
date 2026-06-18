using Marketplace.Domain.Common;
using Marketplace.Domain.Models;

namespace Marketplace.Domain.Repositories;

public interface IAffiliateProductRepository : IGenericRepository<AffiliateProduct>
{
    Task<(IReadOnlyList<AffiliateProduct> Items, int TotalRecords)> SearchPagedAsync(
        AffiliateProductSearchCriteria criteria,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AffiliateProduct>> GetByPartnerIdAsync(
        Guid partnerId,
        CancellationToken cancellationToken = default);

    Task UpdateRatingAsync(Guid id, decimal ratingAverage, int ratingCount, CancellationToken cancellationToken = default);
}
