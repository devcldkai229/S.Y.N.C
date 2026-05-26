using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/posts/{postId:guid}/comments")]
public class CommentController : ControllerBase
{
    private readonly ICommentService _comments;
    private readonly ICurrentUserContext _currentUser;

    public CommentController(ICommentService comments, ICurrentUserContext currentUser)
    {
        _comments = comments;
        _currentUser = currentUser;
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<CommentDto>>> Create(
        Guid postId,
        [FromBody] CreateCommentDto dto,
        CancellationToken cancellationToken)
    {
        var comment = await _comments.CreateAsync(
            _currentUser.RequireUserId(),
            postId,
            dto,
            cancellationToken);
        return Ok(ApiResponse<CommentDto>.SuccessResponse(comment, "Comment created successfully."));
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<CommentDto>>>> GetByPost(
        Guid postId,
        [FromQuery] CommentListQuery query,
        CancellationToken cancellationToken)
    {
        var result = await _comments.GetByPostIdAsync(postId, query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<CommentDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Comments retrieved successfully."));
    }
}
