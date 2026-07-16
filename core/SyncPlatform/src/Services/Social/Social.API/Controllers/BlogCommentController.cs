using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/social/blogs/{blogId:guid}/comments")]
public class BlogCommentController : ControllerBase
{
    private readonly IBlogCommentService _comments;
    private readonly ICurrentUserContext _currentUser;

    public BlogCommentController(IBlogCommentService comments, ICurrentUserContext currentUser)
    {
        _comments = comments;
        _currentUser = currentUser;
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<BlogCommentDto>>> Create(
        Guid blogId,
        [FromBody] CreateBlogCommentDto dto,
        CancellationToken cancellationToken)
    {
        var comment = await _comments.CreateAsync(
            _currentUser.RequireUserId(),
            blogId,
            dto,
            cancellationToken);

        return CreatedAtAction(
            nameof(GetByBlog),
            new { blogId },
            ApiResponse<BlogCommentDto>.SuccessResponse(comment, "Comment created successfully."));
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<BlogCommentDto>>>> GetByBlog(
        Guid blogId,
        [FromQuery] BlogCommentListQuery query,
        CancellationToken cancellationToken)
    {
        var result = await _comments.GetByBlogIdAsync(blogId, query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<BlogCommentDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Blog comments retrieved successfully."));
    }
}
