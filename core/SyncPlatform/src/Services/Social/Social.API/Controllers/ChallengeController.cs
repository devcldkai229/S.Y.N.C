using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/challenges")]
public class ChallengeController : ControllerBase
{
    private readonly ICommunityChallengeService _challenges;
    private readonly ICurrentUserContext _currentUser;

    public ChallengeController(
        ICommunityChallengeService challenges,
        ICurrentUserContext currentUser)
    {
        _challenges = challenges;
        _currentUser = currentUser;
    }

    /// <summary>Create a community challenge (authenticated user or admin). Publishes a feed post automatically.</summary>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> Create(
        [FromBody] CreateCommunityChallengeDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.CreateAsync(
            _currentUser.RequireUserId(),
            dto,
            cancellationToken);

        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Community challenge created successfully."));
    }

    /// <summary>Challenges currently active (Status = Active and within date range).</summary>
    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<CommunityChallengeDto>>>> GetActive(
        CancellationToken cancellationToken)
    {
        var items = await _challenges.GetActiveAsync(cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<CommunityChallengeDto>>.SuccessResponse(
            items,
            "Active challenges retrieved successfully."));
    }
}
