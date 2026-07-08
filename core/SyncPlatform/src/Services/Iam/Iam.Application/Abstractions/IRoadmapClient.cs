namespace Iam.Application.Abstractions;

public interface IRoadmapClient
{
    /// <summary>
    /// Ensures the user has an AI-audit starter PersonalizedRoadmap after email verification.
    /// Idempotent — safe to call multiple times. Best-effort; must not fail registration.
    /// </summary>
    Task EnsureAuditRoadmapAsync(Guid userId, CancellationToken cancellationToken = default);
}
