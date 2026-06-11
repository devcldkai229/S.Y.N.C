using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IChallengeParticipantRepository
{
    Task<ChallengeParticipant?> GetByChallengeAndUserAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Guid>> GetActiveParticipantUserIdsAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ChallengeParticipant> Items, int TotalRecords)> GetPagedByChallengeAsync(
        Guid challengeId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ChallengeParticipant> Items, int TotalRecords)> GetPagedByUserAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateStatusAsync(
        Guid challengeId,
        Guid userId,
        ParticipantStatus expectedCurrentStatus,
        ParticipantStatus newStatus,
        DateTimeOffset? completedAt = null,
        CancellationToken cancellationToken = default);
}
