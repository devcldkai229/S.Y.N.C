using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/social")]
public class InternalSocialAiController : ControllerBase
{
    private readonly ICommunityChallengeService _challenges;

    public InternalSocialAiController(ICommunityChallengeService challenges) => _challenges = challenges;

    [HttpGet("highlights")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<CommunityChallengeDto>>>> GetHighlights(
        [FromQuery] Guid userId,
        [FromQuery] int limit = 5,
        CancellationToken cancellationToken = default)
    {
        _ = userId;
        var query = new ChallengePublicListQuery { PageNumber = 1, PageSize = Math.Clamp(limit, 1, 10) };
        var (items, _) = await _challenges.GetActivePagedAsync(query, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<CommunityChallengeDto>>.SuccessResponse(
            items, "Community highlights retrieved."));
    }
}
