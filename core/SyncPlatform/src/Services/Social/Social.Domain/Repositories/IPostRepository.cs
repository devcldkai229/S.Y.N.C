using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IPostRepository : IGenericRepository<Post>
{
    Task<(IReadOnlyList<Post> Items, int TotalRecords)> GetPublicFeedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Public feed sorted by CreatedAt descending. When <paramref name="cursor"/> is set,
    /// returns posts strictly older than that timestamp.
    /// </summary>
    Task<IReadOnlyList<Post>> GetPublicFeedCursorAsync(
        DateTimeOffset? cursor,
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

    /// <param name="includePrivatePosts">When true, returns all author posts; when false, only <c>IsPublic</c>.</param>
    Task<IReadOnlyList<Post>> GetUserWallCursorAsync(
        Guid authorId,
        DateTimeOffset? cursor,
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
}
