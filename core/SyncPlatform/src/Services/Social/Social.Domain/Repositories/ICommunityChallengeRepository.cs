using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface ICommunityChallengeRepository : IGenericRepository<CommunityChallenge>
{
    Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        ChallengeStatus? status,
        ChallengeGoalType? goalType,
        DateTimeOffset? startDateFrom,
        DateTimeOffset? startDateTo,
        DateTimeOffset? endDateFrom,
        DateTimeOffset? endDateTo,
        ChallengeStatus? requiredStatus = null,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetBrowsablePagedAsync(
        int pageNumber,
        int pageSize,
        ChallengeGoalType? goalType,
        DateTimeOffset? startDateFrom,
        DateTimeOffset? startDateTo,
        DateTimeOffset? endDateFrom,
        DateTimeOffset? endDateTo,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetNearbyActiveAsync(
        double latitude,
        double longitude,
        double radiusKm,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task RefreshStatusAsync(Guid id, ChallengeStatus status, CancellationToken cancellationToken = default);

    Task<bool> IncrementParticipantCountAsync(Guid id, CancellationToken cancellationToken = default);

    Task<bool> DecrementParticipantCountAsync(Guid id, CancellationToken cancellationToken = default);
}
