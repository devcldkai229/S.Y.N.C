using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence.Repositories;

public class ReviewRepository : GenericRepository<Review>, IReviewRepository
{
    public ReviewRepository(IMongoDatabase database) : base(database, "Reviews")
    {
    }

    public async Task<(IReadOnlyList<Review> Items, int TotalRecords)> GetByTargetPagedAsync(
        ReviewTargetType targetType,
        Guid targetId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<Review>.Filter.And(
            Builders<Review>.Filter.Eq(x => x.TargetType, targetType),
            Builders<Review>.Filter.Eq(x => x.TargetId, targetId));

        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<(IReadOnlyList<Review> Items, int TotalRecords)> GetByPartnerScopedAsync(
        Guid partnerId,
        IReadOnlyList<Guid> foodMenuItemIds,
        IReadOnlyList<Guid> affiliateProductIds,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<Review>.Filter;
        var orFilters = new List<FilterDefinition<Review>>
        {
            builder.And(
                builder.Eq(x => x.TargetType, ReviewTargetType.Partner),
                builder.Eq(x => x.TargetId, partnerId)),
        };

        if (foodMenuItemIds.Count > 0)
        {
            orFilters.Add(builder.And(
                builder.Eq(x => x.TargetType, ReviewTargetType.FoodMenuItem),
                builder.In(x => x.TargetId, foodMenuItemIds)));
        }

        if (affiliateProductIds.Count > 0)
        {
            orFilters.Add(builder.And(
                builder.Eq(x => x.TargetType, ReviewTargetType.AffiliateProduct),
                builder.In(x => x.TargetId, affiliateProductIds)));
        }

        var filter = builder.Or(orFilters);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<Review?> GetByUserTargetOrderAsync(
        Guid userId,
        ReviewTargetType targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<Review>.Filter;
        var filter = builder.And(
            builder.Eq(x => x.UserId, userId),
            builder.Eq(x => x.TargetType, targetType),
            builder.Eq(x => x.TargetId, targetId));

        if (orderId.HasValue)
            filter = builder.And(filter, builder.Eq(x => x.OrderId, orderId.Value));
        else
            filter = builder.And(filter, builder.Eq(x => x.OrderId, null));

        return await Collection.Find(filter).FirstOrDefaultAsync(cancellationToken);
    }
}
