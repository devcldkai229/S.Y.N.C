using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IPostRepository : IGenericRepository<Post>
{
    Task<(IReadOnlyList<Post> Items, int TotalRecords)> GetPublicFeedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> GetPublicFeedCursorAsync(
        FeedCursorValue? cursor,
        int limit,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> GetFollowingFeedCursorAsync(
        IReadOnlyList<Guid> authorIds,
        FeedCursorValue? cursor,
        int limit,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<Post> Items, int TotalRecords)> GetByAuthorIdAsync(
        Guid authorId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task IncrementMetricAsync(
        Guid postId,
        Action<PostMetrics> adjust,
        CancellationToken cancellationToken = default);

    Task<int> GetLikeCountAsync(Guid postId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> GetUserWallCursorAsync(
        Guid authorId,
        FeedCursorValue? cursor,
        int limit,
        bool onlyMedia,
        bool includePrivatePosts,
        CancellationToken cancellationToken = default);

    Task<Post?> GetByShareCodeAsync(string shareCode, CancellationToken cancellationToken = default);

    Task<bool> ShareCodeExistsAsync(string shareCode, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> GetPostsWithoutShareCodeAsync(
        int batchSize,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> SearchByTextAsync(
        string query,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Post>> GetRecentPublicPostsAsync(
        DateTimeOffset since,
        int limit,
        CancellationToken cancellationToken = default);
}
