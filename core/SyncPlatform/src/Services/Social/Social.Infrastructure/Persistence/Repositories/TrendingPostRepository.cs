using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class TrendingPostRepository : ITrendingPostRepository
{
    private readonly IMongoCollection<TrendingPost> _collection;

    public TrendingPostRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<TrendingPost>("TrendingPosts");
    }

    public async Task ReplaceAllAsync(
        IReadOnlyList<TrendingPost> items,
        CancellationToken cancellationToken = default)
    {
        await _collection.DeleteManyAsync(FilterDefinition<TrendingPost>.Empty, cancellationToken);
        if (items.Count == 0)
            return;
        await _collection.InsertManyAsync(items, cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<TrendingPost>> GetCursorAsync(
        double? scoreCursor,
        Guid? idCursor,
        int limit,
        CancellationToken cancellationToken = default)
    {
        var fb = Builders<TrendingPost>.Filter;
        var filter = fb.Empty;

        if (scoreCursor.HasValue)
        {
            if (idCursor.HasValue && idCursor.Value != Guid.Empty)
            {
                filter = fb.Or(
                    fb.Lt(x => x.Score, scoreCursor.Value),
                    fb.And(
                        fb.Eq(x => x.Score, scoreCursor.Value),
                        fb.Lt(x => x.Id, idCursor.Value)));
            }
            else
            {
                filter = fb.Lt(x => x.Score, scoreCursor.Value);
            }
        }

        return await _collection.Find(filter)
            .SortByDescending(x => x.Score)
            .ThenByDescending(x => x.Id)
            .Limit(limit)
            .ToListAsync(cancellationToken);
    }
}
