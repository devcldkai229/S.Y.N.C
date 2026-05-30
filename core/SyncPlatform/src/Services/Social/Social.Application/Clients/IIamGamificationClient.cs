namespace Social.Application.Clients;

public interface IIamGamificationClient
{
    /// <summary>
    /// Grants XP and coins to a user for a completed action (e.g. posting to the community).
    /// Fire-and-forget safe — implementation swallows errors so callers are not affected.
    /// </summary>
    Task GrantXpAsync(Guid userId, int xp, int coins, string eventName, CancellationToken cancellationToken = default);
}
