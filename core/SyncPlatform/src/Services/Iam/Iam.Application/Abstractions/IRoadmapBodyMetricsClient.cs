namespace Iam.Application.Abstractions;

/// <summary>
/// Best-effort sync of body weight/fat onto the user's active PersonalizedRoadmap.
/// </summary>
public interface IRoadmapBodyMetricsClient
{
    Task SyncAsync(
        Guid userId,
        decimal currentWeightKg,
        decimal? bodyFatPercentage = null,
        CancellationToken cancellationToken = default);
}
