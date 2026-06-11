using Libs.Shared.Enums;
using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence.Repositories;

public class AffiliateProductRepository : GenericRepository<AffiliateProduct>, IAffiliateProductRepository
{
    public AffiliateProductRepository(IMongoDatabase database) : base(database, "AffiliateProducts")
    {
    }

    public async Task<(IReadOnlyList<AffiliateProduct> Items, int TotalRecords)> SearchPagedAsync(
        AffiliateProductSearchCriteria criteria,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<AffiliateProduct>.Filter;
        var filters = new List<FilterDefinition<AffiliateProduct>>();

        if (criteria.Availability.HasValue)
            filters.Add(builder.Eq(x => x.Availability, criteria.Availability.Value));
        else
            filters.Add(builder.Ne(x => x.Availability, AvailabilityStatus.Hidden));

        if (criteria.Category.HasValue)
            filters.Add(builder.Eq(x => x.Category, criteria.Category.Value));

        if (criteria.DietaryTags is { Count: > 0 })
        {
            foreach (var tag in criteria.DietaryTags)
                filters.Add(builder.AnyEq(x => x.DietaryTags!, tag));
        }

        var filter = filters.Count == 0 ? builder.Empty : builder.And(filters);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.RatingAverage)
            .ThenBy(x => x.NameVi)
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Limit(criteria.PageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<IReadOnlyList<AffiliateProduct>> GetByPartnerIdAsync(
        Guid partnerId,
        CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.PartnerId == partnerId && x.Availability != AvailabilityStatus.Hidden)
            .SortBy(x => x.NameVi)
            .ToListAsync(cancellationToken);
    }

    public async Task UpdateRatingAsync(
        Guid id,
        decimal ratingAverage,
        int ratingCount,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<AffiliateProduct>.Update
            .Set(x => x.RatingAverage, ratingAverage)
            .Set(x => x.RatingCount, ratingCount)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);
        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }
}
