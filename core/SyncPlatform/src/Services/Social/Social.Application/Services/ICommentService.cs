using Social.Application.DTOs;

namespace Social.Application.Services;

public interface ICommentService
{
    Task<CommentDto> CreateAsync(
        Guid userId,
        Guid postId,
        CreateCommentDto dto,
        CancellationToken cancellationToken = default);

    Task<CommentDto> CreateReplyAsync(
        Guid userId,
        Guid commentId,
        CreateReplyDto dto,
        CancellationToken cancellationToken = default);

    Task<PagedResult<CommentDto>> GetByPostIdAsync(
        Guid postId,
        CommentListQuery query,
        CancellationToken cancellationToken = default);
}
