using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Libs.Auth.Context;

namespace Iam.Application.Services;

public sealed class GamificationService : IGamificationService
{
    private readonly IUserMeRepository _repo;
    private readonly ICurrentUserContext _currentUser;
    private readonly IAchievementService _achievements;

    public GamificationService(
        IUserMeRepository repo,
        ICurrentUserContext currentUser,
        IAchievementService achievements)
    {
        _repo = repo;
        _currentUser = currentUser;
        _achievements = achievements;
    }

    public async Task<LogActivityResponse> LogActivityAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.RequireUserId();
        var profile = await _repo.GetGamificationForUpdateAsync(userId, cancellationToken);

        // User has no gamification profile yet (onboarding incomplete)
        if (profile is null)
            return new LogActivityResponse(0, 0, false, []);

        var todayUtc = DateOnly.FromDateTime(DateTimeOffset.UtcNow.UtcDateTime);
        var lastDay = profile.LastActivityDate.HasValue
            ? DateOnly.FromDateTime(profile.LastActivityDate.Value.UtcDateTime)
            : (DateOnly?)null;

        // Idempotent: already logged today
        if (lastDay == todayUtc)
            return new LogActivityResponse(profile.CurrentStreak, profile.LongestStreak, true, []);

        var now = DateTimeOffset.UtcNow;

        if (lastDay == todayUtc.AddDays(-1))
        {
            // Consecutive day — extend streak
            profile.CurrentStreak++;
        }
        else
        {
            // Missed at least one day — reset
            profile.CurrentStreak = 1;
        }

        if (profile.CurrentStreak > profile.LongestStreak)
            profile.LongestStreak = profile.CurrentStreak;

        profile.LastActivityDate = now;
        profile.UpdatedAt = now;

        await _repo.SaveChangesAsync(cancellationToken);

        // Check if streak update unlocked any achievements
        var unlocked = await _achievements.CheckAndUnlockAsync(userId, cancellationToken);

        return new LogActivityResponse(profile.CurrentStreak, profile.LongestStreak, false, unlocked);
    }
}
