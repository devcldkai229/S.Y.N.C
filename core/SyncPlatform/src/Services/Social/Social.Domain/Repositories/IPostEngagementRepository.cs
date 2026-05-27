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
    /// Inserts a comment and increments <see cref="Post.Metrics.CommentCount"/> atomically.
    /// </summary>
    Task<Comment> AddCommentAsync(
        Guid postId,
        Guid userId,
        string content,
        AuthorSnapshot? authorSnapshot,
        CancellationToken cancellationToken = default);
}
