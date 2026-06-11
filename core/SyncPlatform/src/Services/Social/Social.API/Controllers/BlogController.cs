using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/social/blogs")]
public class BlogController : ControllerBase
{
    private readonly IBlogService _blogs;
    private readonly ICurrentUserContext _currentUser;

    public BlogController(IBlogService blogs, ICurrentUserContext currentUser)
    {
        _blogs = blogs;
        _currentUser = currentUser;
    }

    /// <summary>Create a blog post (status = Draft, unique slug from title).</summary>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogDto>>> Create(
        [FromBody] CreateBlogDto dto,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.CreateAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog created successfully."));
    }

    /// <summary>Update a blog (author only, Draft or Archived).</summary>
    [HttpPut("{blogId:guid}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogDto>>> Update(
        Guid blogId,
        [FromBody] UpdateBlogDto dto,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.UpdateAsync(_currentUser.RequireUserId(), blogId, dto, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog updated successfully."));
    }

    /// <summary>Publish a blog (status = Published, PublishedAt = now).</summary>
    [HttpPost("{blogId:guid}/publish")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogDto>>> Publish(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.PublishAsync(_currentUser.RequireUserId(), blogId, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog published successfully."));
    }

    /// <summary>Archive a blog (status = Archived).</summary>
    [HttpPost("{blogId:guid}/archive")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogDto>>> Archive(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.ArchiveAsync(_currentUser.RequireUserId(), blogId, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog archived successfully."));
    }

    /// <summary>Hard-delete a blog (author or SystemAdmin).</summary>
    [HttpDelete("{blogId:guid}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        await _blogs.DeleteAsync(_currentUser.RequireUserId(), _currentUser.Role, blogId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Blog deleted successfully."));
    }

    /// <summary>Paginated published blog feed (optional tag filter).</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<BlogDto>>>> GetPublishedFeed(
        [FromQuery] BlogListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _blogs.GetPublishedFeedAsync(
            query,
            _currentUser.UserId,
            cancellationToken);

        return Ok(PagedApiResponse<IReadOnlyList<BlogDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Published blogs retrieved successfully."));
    }

    /// <summary>Author's blogs (all statuses, author-only).</summary>
    [HttpGet("author/{authorId:guid}")]
    [Authorize]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<BlogDto>>>> GetByAuthor(
        Guid authorId,
        [FromQuery] BlogListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _blogs.GetByAuthorAsync(
            authorId,
            _currentUser.RequireUserId(),
            query,
            cancellationToken);

        return Ok(PagedApiResponse<IReadOnlyList<BlogDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Author blogs retrieved successfully."));
    }

    /// <summary>Get a published blog by slug (author can view own drafts/archives).</summary>
    [HttpGet("slug/{slug}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<BlogDto>>> GetBySlug(
        string slug,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.GetBySlugAsync(slug, _currentUser.UserId, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog retrieved successfully."));
    }

    /// <summary>Get a blog by id (published = public; drafts/archives = author only).</summary>
    [HttpGet("{blogId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<BlogDto>>> GetById(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        var blog = await _blogs.GetByIdAsync(blogId, _currentUser.UserId, cancellationToken);
        return Ok(ApiResponse<BlogDto>.SuccessResponse(blog, "Blog retrieved successfully."));
    }

    [HttpPost("{blogId:guid}/like")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogEngagementResultDto>>> Like(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        var result = await _blogs.LikeAsync(_currentUser.RequireUserId(), blogId, cancellationToken);
        return Ok(ApiResponse<BlogEngagementResultDto>.SuccessResponse(result, "Blog liked successfully."));
    }

    [HttpPost("{blogId:guid}/share")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogEngagementResultDto>>> Share(
        Guid blogId,
        CancellationToken cancellationToken)
    {
        var result = await _blogs.ShareAsync(_currentUser.RequireUserId(), blogId, cancellationToken);
        return Ok(ApiResponse<BlogEngagementResultDto>.SuccessResponse(result, "Blog shared successfully."));
    }
}
