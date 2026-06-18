using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/comments/{commentId:guid}/replies")]
public class CommentReplyController : ControllerBase
{
    private readonly ICommentService _comments;
    private readonly ICurrentUserContext _currentUser;

    public CommentReplyController(ICommentService comments, ICurrentUserContext currentUser)
    {
        _comments = comments;
        _currentUser = currentUser;
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<CommentDto>>> Create(
        Guid commentId,
        [FromBody] CreateReplyDto dto,
        CancellationToken cancellationToken)
    {
        var reply = await _comments.CreateReplyAsync(
            _currentUser.RequireUserId(),
            commentId,
            dto,
            cancellationToken);

        return CreatedAtAction(
            nameof(Create),
            new { commentId },
            ApiResponse<CommentDto>.SuccessResponse(reply, "Reply created successfully."));
    }
}
