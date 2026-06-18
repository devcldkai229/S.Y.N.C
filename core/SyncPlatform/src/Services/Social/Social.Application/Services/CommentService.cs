using Libs.Storage.Services;
using Social.Application.Clients;
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
    private readonly ISocialNotificationClient _notifications;
    private readonly IMediaUrlResolver _media;

    public CommentService(
        IPostRepository posts,
        IPostEngagementRepository engagement,
        ICommentRepository comments,
        ISocialNotificationClient notifications,
        IMediaUrlResolver media)
    {
        _posts = posts;
        _engagement = engagement;
        _comments = comments;
        _notifications = notifications;
        _media = media;
    }

    public async Task<CommentDto> CreateAsync(
        Guid userId,
        Guid postId,
        CreateCommentDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new BadRequestException("Comment content is required.");

        var post = await _posts.GetByIdAsync(postId, cancellationToken)
            ?? throw new NotFoundException($"Post {postId} was not found.");

        var snapshot = BuildAuthorSnapshot(dto.AuthorSnapshot);

        var comment = await _engagement.AddCommentAsync(
            postId,
            userId,
            dto.Content.Trim(),
            snapshot,
            cancellationToken: cancellationToken);

        _ = _notifications.NotifyPostCommentedAsync(
            userId,
            post.AuthorId,
            postId,
            comment.Id,
            cancellationToken);

        return comment.ToDto(_media);
    }

    public async Task<CommentDto> CreateReplyAsync(
        Guid userId,
        Guid commentId,
        CreateReplyDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new BadRequestException("Reply content is required.");

        var parent = await _comments.GetByIdAsync(commentId, cancellationToken)
            ?? throw new NotFoundException($"Comment {commentId} was not found.");

        if (!await _posts.ExistsAsync(parent.PostId, cancellationToken))
            throw new NotFoundException($"Post {parent.PostId} was not found.");

        var snapshot = BuildAuthorSnapshot(dto.AuthorSnapshot);

        var reply = await _engagement.AddCommentAsync(
            parent.PostId,
            userId,
            dto.Content.Trim(),
            snapshot,
            parentCommentId: commentId,
            cancellationToken: cancellationToken);

        _ = _notifications.NotifyCommentRepliedAsync(
            userId,
            parent.UserId,
            parent.PostId,
            reply.Id,
            cancellationToken);

        return reply.ToDto(_media);
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
            Items = items.Select(x => x.ToDto(_media)).ToList(),
            Pagination = new Common.PaginationMetadata
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalRecords = total,
            },
        };
    }

    private static AuthorSnapshot? BuildAuthorSnapshot(AuthorSnapshotDto? dto)
    {
        if (dto is null || string.IsNullOrWhiteSpace(dto.FullName))
            return null;

        return new AuthorSnapshot
        {
            FullName = dto.FullName.Trim(),
            AvatarUrl = dto.AvatarUrl,
        };
    }
}
