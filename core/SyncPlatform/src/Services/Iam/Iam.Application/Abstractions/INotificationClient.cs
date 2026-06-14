namespace Iam.Application.Abstractions;

public interface INotificationClient
{
    /// <summary>
    /// Sends an in-app notification to a user when they unlock an achievement.
    /// Fire-and-forget safe — implementation swallows errors so callers are not affected.
    /// </summary>
    Task SendAchievementUnlockedAsync(Guid userId, string achievementName, CancellationToken cancellationToken = default);
}
