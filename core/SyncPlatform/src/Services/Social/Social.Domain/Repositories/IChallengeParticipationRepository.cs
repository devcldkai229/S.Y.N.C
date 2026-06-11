using Social.Domain.Models;

namespace Social.Domain.Repositories;

/// <summary>
/// Atomic challenge participation writes (MongoDB transaction + $inc on ParticipantCount).
/// </summary>
public interface IChallengeParticipationRepository
{
    Task<ChallengeParticipant> JoinAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<ChallengeParticipant> LeaveAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default);
}
