using Libs.Storage.Services;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public interface IBlogCommentService
{
    Task<BlogCommentDto> CreateAsync(
        Guid userId,
        Guid blogId,
        CreateBlogCommentDto dto,
        CancellationToken cancellationToken = default);

    Task<PagedResult<BlogCommentDto>> GetByBlogIdAsync(
        Guid blogId,
        BlogCommentListQuery query,
        CancellationToken cancellationToken = default);
}

public class BlogCommentService : IBlogCommentService
{
    private readonly IBlogRepository _blogs;
    private readonly IBlogCommentRepository _comments;
    private readonly IMediaUrlResolver _media;

    public BlogCommentService(
        IBlogRepository blogs,
        IBlogCommentRepository comments,
        IMediaUrlResolver media)
    {
        _blogs = blogs;
        _comments = comments;
        _media = media;
    }

    public async Task<BlogCommentDto> CreateAsync(
        Guid userId,
        Guid blogId,
        CreateBlogCommentDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new BadRequestException("Comment content is required.");

        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        if (blog.Status != BlogStatus.Published)
            throw new ForbiddenException("Only published blogs can be commented on.");

        AuthorSnapshot? snapshot = null;
        if (dto.AuthorSnapshot is not null && !string.IsNullOrWhiteSpace(dto.AuthorSnapshot.FullName))
        {
            snapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            };
        }

        var comment = await _comments.CreateAsync(
            new BlogComment
            {
                BlogId = blogId,
                UserId = userId,
                Content = dto.Content.Trim(),
                AuthorSnapshot = snapshot,
            },
            cancellationToken);

        await _blogs.IncrementCommentCountAsync(blogId, cancellationToken);
        return comment.ToDto(_media);
    }

    public async Task<PagedResult<BlogCommentDto>> GetByBlogIdAsync(
        Guid blogId,
        BlogCommentListQuery query,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        if (blog.Status != BlogStatus.Published)
            throw new NotFoundException($"Blog {blogId} was not found.");

        var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
        var pageSize = query.PageSize switch
        {
            < 1 => 20,
            > 100 => 100,
            _ => query.PageSize,
        };

        var (items, total) = await _comments.GetByBlogIdAsync(blogId, pageNumber, pageSize, cancellationToken);

        return new PagedResult<BlogCommentDto>
        {
            Items = items.Select(x => x.ToDto(_media)).ToList(),
            Pagination = new PaginationMetadata
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalRecords = total,
            },
        };
    }
}
