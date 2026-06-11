using Libs.Shared.Enums;
using MongoDB.Bson;
using MongoDB.Driver;
using Nutrition.Domain.Common;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Infrastructure.Persistence.Repositories;

public class FoodItemRepository : GenericRepository<FoodItem>, IFoodItemRepository
{
    public FoodItemRepository(IMongoDatabase database) : base(database, "FoodItems")
    {
    }

    public async Task<FoodItem?> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.Barcode == barcode && x.IsActive).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<FoodItem> Items, int TotalRecords)> SearchPagedAsync(
        FoodItemSearchCriteria criteria,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<FoodItem>.Filter;
        var filter = builder.Eq(x => x.IsActive, true);

        if (!string.IsNullOrWhiteSpace(criteria.Query))
        {
            var query = criteria.Query.Trim();
            var regex = new BsonRegularExpression(query, "i");
            var searchFilter = builder.Or(
                builder.Regex(x => x.NameVi, regex),
                builder.Regex(x => x.NameEn, regex),
                builder.Regex(x => x.Slug, regex),
                builder.Regex(x => x.Brand!, regex));

            if (Guid.TryParse(query, out var id))
                searchFilter = builder.Or(searchFilter, builder.Eq(x => x.Id, id));

            filter = builder.And(filter, searchFilter);
        }

        if (criteria.Category.HasValue)
            filter = builder.And(filter, builder.Eq(x => x.Category, criteria.Category.Value));

        if (criteria.DietaryTags is { Count: > 0 })
        {
            foreach (var tag in criteria.DietaryTags)
                filter = builder.And(filter, builder.AnyEq(x => x.DietaryTags, tag));
        }

        var totalRecords = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortBy(x => x.NameVi)
            .ThenBy(x => x.NameEn)
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Limit(criteria.PageSize)
            .ToListAsync(cancellationToken);

        return (items, totalRecords);
    }
}
