namespace Iam.Application.Abstractions;

public interface IGamificationService
{
    /// <summary>
    /// Logs today's activity for the current user, updating their streak.
    /// Idempotent — calling more than once on the same day is safe.
    /// Also auto-checks and unlocks any newly met achievements.
    /// </summary>
    Task<DTOs.LogActivityResponse> LogActivityAsync(CancellationToken cancellationToken = default);
}
