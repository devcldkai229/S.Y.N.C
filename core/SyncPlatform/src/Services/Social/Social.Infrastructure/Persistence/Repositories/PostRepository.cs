using System.Text.RegularExpressions;
using MongoDB.Bson;
using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class PostRepository : GenericRepository<Post>, IPostRepository
{
    public PostRepository(IMongoDatabase database) : base(database, "Posts")
    {
    }

    public async Task<(IReadOnlyList<Post> Items, int TotalRecords)> GetPublicFeedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<Post>.Filter.Eq(x => x.IsPublic, true);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<IReadOnlyList<Post>> GetPublicFeedCursorAsync(
        DateTimeOffset? cursor,
        int limit,
        CancellationToken cancellationToken = default)
    {
        var filterBuilder = Builders<Post>.Filter;
        var filter = filterBuilder.Eq(x => x.IsPublic, true);

        if (cursor.HasValue)
            filter &= filterBuilder.Lt(x => x.CreatedAt, cursor.Value);

        return await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Limit(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<Post> Items, int TotalRecords)> GetByAuthorIdAsync(
        Guid authorId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<Post>.Filter.Eq(x => x.AuthorId, authorId);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task IncrementMetricAsync(
        Guid postId,
        Action<PostMetrics> adjust,
        CancellationToken cancellationToken = default)
    {
        var post = await GetByIdAsync(postId, cancellationToken)
            ?? throw new InvalidOperationException($"Post {postId} not found.");

        adjust(post.Metrics);
        post.UpdatedAt = DateTimeOffset.UtcNow;
        await UpdateAsync(postId, post, cancellationToken);
    }

    public async Task<int> GetLikeCountAsync(Guid postId, CancellationToken cancellationToken = default)
    {
        var post = await GetByIdAsync(postId, cancellationToken);
        return post?.Metrics.LikeCount ?? 0;
    }

    public async Task<IReadOnlyList<Post>> GetUserWallCursorAsync(
        Guid authorId,
        DateTimeOffset? cursor,
        int limit,
        bool onlyMedia,
        bool includePrivatePosts,
        CancellationToken cancellationToken = default)
    {
        var filterBuilder = Builders<Post>.Filter;
        var filter = filterBuilder.Eq(x => x.AuthorId, authorId);

        if (!includePrivatePosts)
            filter &= filterBuilder.Eq(x => x.IsPublic, true);

        if (cursor.HasValue)
            filter &= filterBuilder.Lt(x => x.CreatedAt, cursor.Value);

        if (onlyMedia)
            filter &= filterBuilder.SizeGt(x => x.MediaUrls, 0);

        return await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Limit(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Post>> GetPostsWithoutShareCodeAsync(
        int batchSize,
        CancellationToken cancellationToken = default)
    {
        var filterBuilder = Builders<Post>.Filter;
        var missingShareCode = filterBuilder.Or(
            filterBuilder.Eq(x => x.ShareCode, string.Empty),
            filterBuilder.Exists(x => x.ShareCode, false));

        return await Collection.Find(missingShareCode)
            .SortBy(x => x.CreatedAt)
            .Limit(batchSize)
            .ToListAsync(cancellationToken);
    }

    public async Task<Post?> GetByShareCodeAsync(string shareCode, CancellationToken cancellationToken = default)
    {
        var normalized = shareCode.Trim().ToUpperInvariant();
        return await Collection
            .Find(x => x.ShareCode == normalized)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<bool> ShareCodeExistsAsync(string shareCode, CancellationToken cancellationToken = default)
    {
        var normalized = shareCode.Trim().ToUpperInvariant();
        var count = await Collection.CountDocumentsAsync(
            x => x.ShareCode == normalized,
            cancellationToken: cancellationToken);
        return count > 0;
    }

    public async Task<IReadOnlyList<Post>> SearchByTextAsync(
        string query,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var trimmed = query.Trim();
        if (trimmed.Length < 2)
            return [];

        var escaped = Regex.Escape(trimmed);
        var pattern = $"(?i).*{escaped}.*";
        var regex = new BsonRegularExpression(pattern);

        var filterBuilder = Builders<Post>.Filter;
        var filter = filterBuilder.Or(
            filterBuilder.Regex(x => x.Content, regex),
            filterBuilder.Regex("AuthorSnapshot.FullName", regex));

        return await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Limit(take)
            .ToListAsync(cancellationToken);
    }
}
