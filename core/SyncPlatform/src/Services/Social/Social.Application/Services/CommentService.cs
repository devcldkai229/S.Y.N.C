using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Mappers;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class CommentService : ICommentService
{
    private readonly IPostRepository _posts;
    private readonly IPostEngagementRepository _engagement;
    private readonly ICommentRepository _comments;

    public CommentService(
        IPostRepository posts,
        IPostEngagementRepository engagement,
        ICommentRepository comments)
    {
        _posts = posts;
        _engagement = engagement;
        _comments = comments;
    }

    public async Task<CommentDto> CreateAsync(
        Guid userId,
        Guid postId,
        CreateCommentDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new BadRequestException("Comment content is required.");

        if (!await _posts.ExistsAsync(postId, cancellationToken))
            throw new NotFoundException($"Post {postId} was not found.");

        AuthorSnapshot? snapshot = null;
        if (dto.AuthorSnapshot is not null && !string.IsNullOrWhiteSpace(dto.AuthorSnapshot.FullName))
        {
            snapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            };
        }

        var comment = await _engagement.AddCommentAsync(
            postId,
            userId,
            dto.Content.Trim(),
            snapshot,
            cancellationToken);

        return comment.ToDto();
    }

    public async Task<PagedResult<CommentDto>> GetByPostIdAsync(
        Guid postId,
        CommentListQuery query,
        CancellationToken cancellationToken = default)
    {
        if (!await _posts.ExistsAsync(postId, cancellationToken))
            throw new NotFoundException($"Post {postId} was not found.");

        var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
        var pageSize = query.PageSize switch
        {
            < 1 => 20,
            > 100 => 100,
            _ => query.PageSize,
        };

        var (items, total) = await _comments.GetByPostIdAsync(
            postId,
            pageNumber,
            pageSize,
            cancellationToken);

        return new PagedResult<CommentDto>
        {
            Items = items.Select(x => x.ToDto()).ToList(),
            Pagination = new Common.PaginationMetadata
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalRecords = total,
            },
        };
    }
}
