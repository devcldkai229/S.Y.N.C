using Social.Domain.Models;

namespace Social.Domain.Repositories;

/// <summary>
/// Atomic post engagement writes (MongoDB transaction + $inc).
/// </summary>
public interface IPostEngagementRepository
{
    /// <summary>
    /// Inserts a Like interaction and increments <see cref="Post.Metrics.LikeCount"/> atomically.
    /// </summary>
    /// <exception cref="DuplicateLikeException">User already liked this post.</exception>
    Task<Interaction> LikePostAsync(Guid postId, Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes a Like interaction and decrements <see cref="Post.Metrics.LikeCount"/>. Idempotent — no-op if not liked.
    /// </summary>
    Task UnlikePostAsync(Guid postId, Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the subset of <paramref name="postIds"/> that <paramref name="userId"/> has liked.
    /// </summary>
    Task<HashSet<Guid>> GetLikedPostIdsAsync(Guid userId, IEnumerable<Guid> postIds, CancellationToken cancellationToken = default);

    /// <summary>
    /// Inserts a comment and increments <see cref="Post.Metrics.CommentCount"/> atomically.
    /// </summary>
    Task<Comment> AddCommentAsync(
        Guid postId,
        Guid userId,
        string content,
        AuthorSnapshot? authorSnapshot,
        Guid? parentCommentId = null,
        CancellationToken cancellationToken = default);
}
