using Libs.Storage.Services;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class BlogService : IBlogService
{
    private const string AdminRole = "SystemAdmin";

    private readonly IBlogRepository _blogs;
    private readonly IBlogInteractionRepository _interactions;
    private readonly IMediaUrlResolver _media;

    public BlogService(IBlogRepository blogs, IBlogInteractionRepository interactions, IMediaUrlResolver media)
    {
        _blogs = blogs;
        _interactions = interactions;
        _media = media;
    }

    public async Task<BlogDto> CreateAsync(
        Guid authorId,
        CreateBlogDto dto,
        CancellationToken cancellationToken = default)
    {
        ValidateTitle(dto.Title);
        ValidateAuthorSnapshot(dto.AuthorSnapshot);

        var slug = await BlogSlugGenerator.AssignUniqueSlugAsync(_blogs, dto.Title, cancellationToken: cancellationToken);

        var blog = new Blog
        {
            AuthorId = authorId,
            AuthorSnapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            },
            Title = dto.Title.Trim(),
            Slug = slug,
            CoverImageUrl = dto.CoverImageUrl?.Trim() ?? string.Empty,
            MediaUrls = dto.MediaUrls?.Where(u => !string.IsNullOrWhiteSpace(u)).Select(u => u.Trim()).ToArray() ?? [],
            Content = dto.Content?.Trim() ?? string.Empty,
            Tags = NormalizeTags(dto.Tags),
            Status = BlogStatus.Draft,
        };

        await _blogs.CreateAsync(blog, cancellationToken);
        return blog.ToDto(isLikedByMe: false, media: _media);
    }

    public async Task<BlogDto> UpdateAsync(
        Guid authorId,
        Guid blogId,
        UpdateBlogDto dto,
        CancellationToken cancellationToken = default)
    {
        ValidateTitle(dto.Title);

        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        EnsureAuthor(authorId, blog);
        EnsureEditableStatus(blog);

        var titleChanged = !string.Equals(blog.Title, dto.Title.Trim(), StringComparison.Ordinal);
        blog.Title = dto.Title.Trim();
        blog.Content = dto.Content?.Trim() ?? string.Empty;
        blog.CoverImageUrl = dto.CoverImageUrl?.Trim() ?? string.Empty;
        blog.MediaUrls = dto.MediaUrls?.Where(u => !string.IsNullOrWhiteSpace(u)).Select(u => u.Trim()).ToArray() ?? [];
        blog.Tags = NormalizeTags(dto.Tags);

        if (titleChanged)
        {
            blog.Slug = await BlogSlugGenerator.AssignUniqueSlugAsync(
                _blogs,
                blog.Title,
                blog.Id,
                cancellationToken);
        }

        await _blogs.UpdateAsync(blog, cancellationToken);

        var isLiked = await _interactions.HasInteractionAsync(
            blogId,
            authorId,
            InteractionType.Like,
            cancellationToken);

        return blog.ToDto(isLiked, _media);
    }

    public async Task<BlogDto> PublishAsync(
        Guid authorId,
        Guid blogId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        EnsureAuthor(authorId, blog);

        if (blog.Status == BlogStatus.Published)
            throw new ConflictException("Blog is already published.");

        blog.Status = BlogStatus.Published;
        blog.PublishedAt = DateTimeOffset.UtcNow;
        await _blogs.UpdateAsync(blog, cancellationToken);

        var isLiked = await _interactions.HasInteractionAsync(
            blogId,
            authorId,
            InteractionType.Like,
            cancellationToken);

        return blog.ToDto(isLiked, _media);
    }

    public async Task<BlogDto> ArchiveAsync(
        Guid authorId,
        Guid blogId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        EnsureAuthor(authorId, blog);

        if (blog.Status == BlogStatus.Archived)
            throw new ConflictException("Blog is already archived.");

        blog.Status = BlogStatus.Archived;
        await _blogs.UpdateAsync(blog, cancellationToken);

        var isLiked = await _interactions.HasInteractionAsync(
            blogId,
            authorId,
            InteractionType.Like,
            cancellationToken);

        return blog.ToDto(isLiked, _media);
    }

    public async Task DeleteAsync(
        Guid userId,
        string? role,
        Guid blogId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        var isAdmin = string.Equals(role, AdminRole, StringComparison.Ordinal);
        if (blog.AuthorId != userId && !isAdmin)
            throw new ForbiddenException("Only the author or an admin can delete this blog.");

        var deleted = await _blogs.DeleteAsync(blogId, cancellationToken);
        if (!deleted)
            throw new NotFoundException($"Blog {blogId} was not found.");
    }

    public async Task<BlogDto> GetByIdAsync(
        Guid blogId,
        Guid? viewerId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        EnsureCanView(blog, viewerId);

        var isLiked = viewerId.HasValue &&
            await _interactions.HasInteractionAsync(blogId, viewerId.Value, InteractionType.Like, cancellationToken);

        return blog.ToDto(isLiked, _media);
    }

    public async Task<BlogDto> GetBySlugAsync(
        string slug,
        Guid? viewerId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(slug))
            throw new BadRequestException("Slug is required.");

        var blog = await _blogs.GetBySlugAsync(slug.Trim(), cancellationToken)
            ?? throw new NotFoundException($"Blog with slug '{slug}' was not found.");

        EnsureCanView(blog, viewerId);

        var isLiked = viewerId.HasValue &&
            await _interactions.HasInteractionAsync(blog.Id, viewerId.Value, InteractionType.Like, cancellationToken);

        return blog.ToDto(isLiked, _media);
    }

    public async Task<(IReadOnlyList<BlogDto> Items, PaginationMetadata Pagination)> GetPublishedFeedAsync(
        BlogListQuery query,
        Guid? viewerId,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _blogs.GetPublishedAsync(
            pageNumber,
            pageSize,
            query.Tag,
            cancellationToken);

        var likedIds = viewerId.HasValue
            ? await _interactions.GetLikedBlogIdsAsync(viewerId.Value, items.Select(x => x.Id), cancellationToken)
            : [];

        var dtos = items
            .Select(b => b.ToDto(likedIds.Contains(b.Id), _media))
            .ToList();

        return (dtos, BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<(IReadOnlyList<BlogDto> Items, PaginationMetadata Pagination)> GetByAuthorAsync(
        Guid authorId,
        Guid viewerId,
        BlogListQuery query,
        CancellationToken cancellationToken = default)
    {
        if (authorId != viewerId)
            throw new ForbiddenException("You can only view your own blog drafts and archives.");

        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _blogs.GetByAuthorAsync(authorId, pageNumber, pageSize, cancellationToken);
        var likedIds = await _interactions.GetLikedBlogIdsAsync(viewerId, items.Select(x => x.Id), cancellationToken);

        var dtos = items
            .Select(b => b.ToDto(likedIds.Contains(b.Id), _media))
            .ToList();

        return (dtos, BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<BlogEngagementResultDto> LikeAsync(
        Guid userId,
        Guid blogId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        if (blog.Status != BlogStatus.Published)
            throw new ForbiddenException("Only published blogs can be liked.");

        var interaction = new BlogInteraction
        {
            BlogId = blogId,
            UserId = userId,
            InteractionType = InteractionType.Like,
        };

        var created = await _interactions.TryCreateAsync(interaction, cancellationToken);
        if (!created)
            throw new ConflictException("You have already liked this blog.");

        await _blogs.IncrementLikeCountAsync(blogId, cancellationToken);

        var updated = await _blogs.GetByIdAsync(blogId, cancellationToken);
        return new BlogEngagementResultDto
        {
            BlogId = blogId,
            LikeCount = updated?.LikeCount ?? blog.LikeCount + 1,
            ShareCount = updated?.ShareCount ?? blog.ShareCount,
        };
    }

    public async Task<BlogEngagementResultDto> ShareAsync(
        Guid userId,
        Guid blogId,
        CancellationToken cancellationToken = default)
    {
        var blog = await _blogs.GetByIdAsync(blogId, cancellationToken)
            ?? throw new NotFoundException($"Blog {blogId} was not found.");

        if (blog.Status != BlogStatus.Published)
            throw new ForbiddenException("Only published blogs can be shared.");

        var interaction = new BlogInteraction
        {
            BlogId = blogId,
            UserId = userId,
            InteractionType = InteractionType.Share,
        };

        var created = await _interactions.TryCreateAsync(interaction, cancellationToken);
        if (!created)
            throw new ConflictException("You have already shared this blog.");

        await _blogs.IncrementShareCountAsync(blogId, cancellationToken);

        var updated = await _blogs.GetByIdAsync(blogId, cancellationToken);
        return new BlogEngagementResultDto
        {
            BlogId = blogId,
            LikeCount = updated?.LikeCount ?? blog.LikeCount,
            ShareCount = updated?.ShareCount ?? blog.ShareCount + 1,
        };
    }

    private static void ValidateTitle(string title)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new BadRequestException("Title is required.");
    }

    private static void ValidateAuthorSnapshot(AuthorSnapshotDto snapshot)
    {
        if (string.IsNullOrWhiteSpace(snapshot.FullName))
            throw new BadRequestException("AuthorSnapshot.FullName is required.");
    }

    private static void EnsureAuthor(Guid authorId, Blog blog)
    {
        if (blog.AuthorId != authorId)
            throw new ForbiddenException("Only the author can modify this blog.");
    }

    private static void EnsureEditableStatus(Blog blog)
    {
        if (blog.Status == BlogStatus.Published)
            throw new ForbiddenException("Published blogs cannot be edited. Archive the blog first.");
    }

    private static void EnsureCanView(Blog blog, Guid? viewerId)
    {
        if (blog.Status == BlogStatus.Published)
            return;

        if (viewerId.HasValue && blog.AuthorId == viewerId.Value)
            return;

        throw new NotFoundException($"Blog {blog.Id} was not found.");
    }

    private static List<string> NormalizeTags(IEnumerable<string>? tags) =>
        tags?
            .Where(t => !string.IsNullOrWhiteSpace(t))
            .Select(t => t.Trim().ToLowerInvariant())
            .Distinct(StringComparer.Ordinal)
            .ToList() ?? [];

    private static PaginationMetadata BuildPagination(int pageNumber, int pageSize, int totalRecords) =>
        new()
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = totalRecords,
        };
}
