using System.Text.Json;
using Iam.Application.Abstractions;
using Iam.Application.Models;
using Iam.Domain.Models;

namespace Iam.Application.Services;

public sealed class AchievementService : IAchievementService
{
    private readonly IUserMeRepository _repo;
    private readonly INotificationClient _notifications;

    private static readonly JsonSerializerOptions _jsonOpts =
        new(JsonSerializerDefaults.Web);

    public AchievementService(IUserMeRepository repo, INotificationClient notifications)
    {
        _repo = repo;
        _notifications = notifications;
    }

    public async Task<IReadOnlyList<string>> CheckAndUnlockAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var profile = await _repo.GetGamificationForUpdateAsync(userId, cancellationToken);
        if (profile is null) return [];

        var allAchievements = await _repo.GetAllAchievementsAsync(cancellationToken);
        var unlockedIds = await _repo.GetUnlockedAchievementIdsAsync(userId, cancellationToken);

        var newCodes = new List<string>();
        var now = DateTimeOffset.UtcNow;

        foreach (var achievement in allAchievements)
        {
            if (unlockedIds.Contains(achievement.Id)) continue;
            if (!EvaluateProfileRequirement(achievement.RequirementJson, profile)) continue;

            _repo.AddUserAchievement(new UserAchievement
            {
                UserId = userId,
                AchievementId = achievement.Id,
                UnlockedAt = now,
                CreatedAt = now,
                UpdatedAt = now,
            });

            profile.CurrentXP += achievement.XPReward;
            profile.SyncCoins += achievement.CoinReward;
            profile.AchievementPoints += achievement.XPReward / 10;
            profile.UpdatedAt = now;

            newCodes.Add(achievement.Code);

            // Fire-and-forget in-app notification
            _ = _notifications.SendAchievementUnlockedAsync(userId, achievement.Name, cancellationToken);
        }

        if (newCodes.Count > 0)
        {
            CheckLevelUp(profile);
            await _repo.SaveChangesAsync(cancellationToken);
        }

        return newCodes;
    }

    public async Task GrantXpAndCoinsAsync(
        Guid userId, int xp, int coins,
        CancellationToken cancellationToken = default)
    {
        var profile = await _repo.GetGamificationForUpdateAsync(userId, cancellationToken);
        if (profile is null) return;

        var now = DateTimeOffset.UtcNow;
        profile.CurrentXP += xp;
        profile.SyncCoins += coins;
        profile.UpdatedAt = now;

        CheckLevelUp(profile);
        await _repo.SaveChangesAsync(cancellationToken);

        // Check if the new XP/level unlocked any achievements
        await CheckAndUnlockAsync(userId, cancellationToken);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /// Evaluates only profile-based requirements (streak, perfect_days, level).
    /// Event-based requirements ("event" type) are triggered externally via GrantXpAndCoins.
    private static bool EvaluateProfileRequirement(string? json, GamificationProfile profile)
    {
        if (string.IsNullOrWhiteSpace(json)) return false;
        try
        {
            var req = JsonSerializer.Deserialize<AchievementRequirement>(json, _jsonOpts);
            return req?.Type switch
            {
                "streak" => profile.CurrentStreak >= (req.Days ?? int.MaxValue),
                "perfect_days" => profile.ConsecutivePerfectDays >= (req.Days ?? int.MaxValue),
                "level" => profile.CurrentLevel >= (req.Level ?? int.MaxValue),
                _ => false,
            };
        }
        catch
        {
            return false;
        }
    }

    private static void CheckLevelUp(GamificationProfile profile) => CheckLevelUpStatic(profile);

    public static void CheckLevelUpStatic(GamificationProfile profile)
    {
        while (profile.CurrentXP >= XpRequiredForLevel(profile.CurrentLevel + 1))
            profile.CurrentLevel++;
    }

    /// XP required to reach a given level.
    /// Level 1 = 0, Level 2 = 100, Level 5 ≈ 716, Level 10 ≈ 3162, Level 25 ≈ 29067.
    public static long XpRequiredForLevel(int level) =>
        level <= 1 ? 0 : (long)(100 * Math.Pow(level - 1, 1.8));
}
