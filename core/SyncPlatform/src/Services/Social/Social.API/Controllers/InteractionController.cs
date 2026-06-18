using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/posts/{postId:guid}/interactions")]
public class InteractionController : ControllerBase
{
    private readonly IInteractionService _interactions;
    private readonly ICurrentUserContext _currentUser;

    public InteractionController(IInteractionService interactions, ICurrentUserContext currentUser)
    {
        _interactions = interactions;
        _currentUser = currentUser;
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<InteractionDto>>> Create(
        Guid postId,
        [FromBody] CreateInteractionDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _interactions.AddAsync(
            _currentUser.RequireUserId(),
            postId,
            dto,
            cancellationToken);
        return Ok(ApiResponse<InteractionDto>.SuccessResponse(result, "Interaction recorded successfully."));
    }
}
