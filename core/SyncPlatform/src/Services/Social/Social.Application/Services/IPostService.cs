using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IPostService
{
    Task<PostDto> CreateAsync(Guid authorId, CreatePostDto dto, CancellationToken cancellationToken = default);
    Task<PostDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<CursorFeedResult<PostDto>> GetPublicFeedCursorAsync(
        FeedCursorQuery query,
        CancellationToken cancellationToken = default);

    /// <summary>Public profile wall — public posts only.</summary>
    Task<CursorFeedResult<PostDto>> GetUserWallCursorAsync(
        Guid userId,
        UserWallQuery query,
        CancellationToken cancellationToken = default);

    /// <summary>Authenticated owner wall — includes private posts.</summary>
    Task<CursorFeedResult<PostDto>> GetMyWallCursorAsync(
        Guid ownerId,
        UserWallQuery query,
        CancellationToken cancellationToken = default);

    Task<PostDto> GetByShareCodeAsync(string shareCode, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid authorId, Guid postId, CancellationToken cancellationToken = default);

    Task<LikePostResultDto> LikePostAsync(
        Guid userId,
        Guid postId,
        CancellationToken cancellationToken = default);

    Task UnlikePostAsync(Guid userId, Guid postId, CancellationToken cancellationToken = default);
}

public sealed class PagedResult<T>
{
    public required IReadOnlyList<T> Items { get; init; }
    public required PaginationMetadata Pagination { get; init; }
}

public sealed class CursorFeedResult<T>
{
    public required IReadOnlyList<T> Items { get; init; }
    public string? NextCursor { get; init; }
}
