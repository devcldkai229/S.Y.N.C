using Iam.Application.Abstractions;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

public sealed record InternalNextAchievementDto(
    string Code,
    string Name,
    int CurrentValue,
    int RequiredValue);

[ApiController]
[Route("api/internal/gamification")]
[AllowAnonymous]
public class InternalGamificationController : ControllerBase
{
    private readonly IAchievementService _achievementService;
    private readonly IUserMeRepository _userMeRepository;

    public InternalGamificationController(
        IAchievementService achievementService,
        IUserMeRepository userMeRepository)
    {
        _achievementService = achievementService;
        _userMeRepository = userMeRepository;
    }

    [HttpGet("{userId:guid}")]
    public async Task<ActionResult<ApiResponse<GamificationSummaryDto>>> GetStatus(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var profile = await _userMeRepository.GetGamificationAsync(userId, cancellationToken);
        if (profile == null)
        {
            return NotFound(ApiResponse<GamificationSummaryDto>.FailureResponse(
                $"Gamification profile not found for user {userId}."));
        }

        return Ok(ApiResponse<GamificationSummaryDto>.SuccessResponse(
            MapGamification(profile),
            "Gamification status retrieved."));
    }

    [HttpGet("{userId:guid}/next-achievement")]
    public async Task<ActionResult<ApiResponse<InternalNextAchievementDto?>>> GetNextAchievement(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await _achievementService.CheckAndUnlockAsync(userId, cancellationToken);
        var gamification = await _userMeRepository.GetGamificationAsync(userId, cancellationToken);
        var all = await _userMeRepository.GetAllAchievementsAsync(cancellationToken);
        var unlocked = await _userMeRepository.GetUnlockedAchievementIdsAsync(userId, cancellationToken);

        var next = all
            .Where(a => !unlocked.Contains(a.Id))
            .Select(a => ToProgress(a, gamification))
            .Where(p => p is not null)
            .OrderByDescending(p => p!.RequiredValue > 0 ? (double)p.CurrentValue / p.RequiredValue : 0)
            .FirstOrDefault();

        return Ok(ApiResponse<InternalNextAchievementDto?>.SuccessResponse(next, "Next achievement retrieved."));
    }

    private static GamificationSummaryDto MapGamification(Domain.Models.GamificationProfile profile) =>
        new(
            profile.CurrentLevel,
            profile.CurrentXP,
            profile.CurrentStreak,
            profile.LongestStreak,
            profile.SyncCoins,
            profile.AchievementPoints,
            profile.ConsecutivePerfectDays);

    private static InternalNextAchievementDto? ToProgress(
        Domain.Models.Achievement achievement,
        Domain.Models.GamificationProfile? profile)
    {
        if (profile is null) return null;
        var (current, required) = achievement.Code switch
        {
            _ when achievement.RequirementJson?.Contains("streak", StringComparison.OrdinalIgnoreCase) == true
                => (profile.CurrentStreak, 7),
            _ => (0, 1),
        };
        if (required <= 0) return null;
        return new InternalNextAchievementDto(
            achievement.Code,
            achievement.Name,
            current,
            required);
    }

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
