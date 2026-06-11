using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/users/me/challenges")]
public class UserChallengeController : ControllerBase
{
    private readonly IChallengeParticipationService _participation;
    private readonly ICurrentUserContext _currentUser;

    public UserChallengeController(
        IChallengeParticipationService participation,
        ICurrentUserContext currentUser)
    {
        _participation = participation;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<UserChallengeDto>>>> GetMyChallenges(
        [FromQuery] UserChallengeListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _participation.GetMyChallengesAsync(
            _currentUser.RequireUserId(),
            query,
            cancellationToken);

        return Ok(PagedApiResponse<IReadOnlyList<UserChallengeDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Your challenges retrieved successfully."));
    }
}
