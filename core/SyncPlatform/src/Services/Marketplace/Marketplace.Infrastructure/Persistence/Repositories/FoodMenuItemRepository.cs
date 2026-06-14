using Libs.Shared.Enums;
using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence.Repositories;

public class FoodMenuItemRepository : GenericRepository<FoodMenuItem>, IFoodMenuItemRepository
{
    public FoodMenuItemRepository(IMongoDatabase database) : base(database, "FoodMenuItems")
    {
    }

    public async Task<IReadOnlyList<FoodMenuItem>> GetByPartnerIdAsync(
        Guid partnerId,
        AvailabilityStatus? availability = null,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<FoodMenuItem>.Filter;
        var filter = builder.Eq(x => x.PartnerId, partnerId);
        if (availability.HasValue)
            filter = builder.And(filter, builder.Eq(x => x.Availability, availability.Value));
        else
            filter = builder.And(filter, builder.Ne(x => x.Availability, AvailabilityStatus.Hidden));

        return await Collection.Find(filter)
            .SortBy(x => x.NameVi)
            .ToListAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<FoodMenuItem> Items, int TotalRecords)> SearchPagedAsync(
        FoodMenuItemSearchCriteria criteria,
        CancellationToken cancellationToken = default)
    {
        var filter = BuildFilter(criteria);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.RatingAverage)
            .ThenBy(x => x.NameVi)
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Limit(criteria.PageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<IReadOnlyList<FoodMenuItem>> GetRandomAsync(
        FoodMenuItemSearchCriteria criteria,
        int count,
        CancellationToken cancellationToken = default)
    {
        var filter = BuildFilter(criteria);
        var sampleSize = Math.Clamp(count, 1, 50);

        return await Collection.Aggregate()
            .Match(filter)
            .Sample(sampleSize)
            .ToListAsync(cancellationToken);
    }

    public async Task UpdateRatingAsync(
        Guid id,
        decimal ratingAverage,
        int ratingCount,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<FoodMenuItem>.Update
            .Set(x => x.RatingAverage, ratingAverage)
            .Set(x => x.RatingCount, ratingCount)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);
        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }

    private static FilterDefinition<FoodMenuItem> BuildFilter(FoodMenuItemSearchCriteria criteria)
    {
        var builder = Builders<FoodMenuItem>.Filter;
        var filters = new List<FilterDefinition<FoodMenuItem>>();

        if (criteria.Availability.HasValue)
            filters.Add(builder.Eq(x => x.Availability, criteria.Availability.Value));
        else
            filters.Add(builder.Ne(x => x.Availability, AvailabilityStatus.Hidden));

        if (!string.IsNullOrWhiteSpace(criteria.Query))
        {
            var query = criteria.Query.Trim();
            var regex = new BsonRegularExpression(query, "i");
            filters.Add(builder.Or(
                builder.Regex(x => x.NameVi, regex),
                builder.Regex(x => x.NameEn, regex),
                builder.Regex(x => x.Slug, regex)));
        }

        if (criteria.Category.HasValue)
            filters.Add(builder.Eq(x => x.Category, criteria.Category.Value));

        if (criteria.DietaryTags is { Count: > 0 })
        {
            foreach (var tag in criteria.DietaryTags)
                filters.Add(builder.AnyEq(x => x.DietaryTags, tag));
        }

        if (criteria.MinPrice.HasValue)
            filters.Add(builder.Gte(x => x.Price, criteria.MinPrice.Value));
        if (criteria.MaxPrice.HasValue)
            filters.Add(builder.Lte(x => x.Price, criteria.MaxPrice.Value));

        if (criteria.PartnerIds is { Count: > 0 })
            filters.Add(builder.In(x => x.PartnerId, criteria.PartnerIds));

        return filters.Count == 0 ? builder.Empty : builder.And(filters);
    }
}
