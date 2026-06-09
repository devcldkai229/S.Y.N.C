using Iam.Application.Abstractions;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/internal/gamification")]
public class InternalGamificationController : ControllerBase
{
    private readonly IAchievementService _achievementService;

    public InternalGamificationController(IAchievementService achievementService)
    {
        _achievementService = achievementService;
    }

    /// <summary>
    /// Grant XP and coins to a user. Called by other services (workout, social, roadmap)
    /// after an event such as completing a workout or posting to the community.
    /// Also triggers achievement unlock checks automatically.
    /// </summary>
    [HttpPost("grant")]
    public async Task<ActionResult<ApiResponse<object>>> Grant(
        [FromBody] GrantXpRequest request,
        CancellationToken cancellationToken)
    {
        await _achievementService.GrantXpAndCoinsAsync(
            request.UserId, request.Xp, request.Coins, cancellationToken);

        return Ok(ApiResponse<object>.SuccessResponse(new { },
            $"Granted {request.Xp} XP and {request.Coins} coins to user {request.UserId}."));
    }

    /// <summary>
    /// Manually trigger achievement check for a user (e.g. after a streak update).
    /// Returns the codes of newly unlocked achievements.
    /// </summary>
    [HttpPost("check/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<string>>>> Check(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var unlocked = await _achievementService.CheckAndUnlockAsync(userId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<string>>.SuccessResponse(unlocked,
            $"Achievement check complete. {unlocked.Count} new achievement(s) unlocked."));
    }
}
