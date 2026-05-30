namespace Iam.Application.Abstractions;

public interface IAchievementService
{
    /// <summary>
    /// Evaluates all profile-based achievements (streak, perfect_days, level) and unlocks
    /// any that are newly met. Also grants XP/coins and triggers level-ups for new unlocks.
    /// Returns the codes of newly unlocked achievements.
    /// </summary>
    Task<IReadOnlyList<string>> CheckAndUnlockAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Adds XP and coins to the user's gamification profile, handles level-up, then checks achievements.
    /// Called by other services (workout, social) via the internal gamification endpoint.
    /// </summary>
    Task GrantXpAndCoinsAsync(Guid userId, int xp, int coins, CancellationToken cancellationToken = default);
}
