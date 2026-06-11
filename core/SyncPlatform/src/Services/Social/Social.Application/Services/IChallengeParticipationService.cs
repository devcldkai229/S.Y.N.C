using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IChallengeParticipationService
{
    Task<ChallengeParticipantDto> JoinAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default);

    Task<ChallengeParticipantDto> LeaveAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default);

    Task<ChallengeParticipantDto> StartProgressAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default);

    Task<ChallengeParticipantDto> CompleteAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ChallengeParticipantDto> Items, PaginationMetadata Pagination)> GetParticipantsAsync(
        Guid challengeId,
        ChallengeParticipantListQuery query,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<UserChallengeDto> Items, PaginationMetadata Pagination)> GetMyChallengesAsync(
        Guid userId,
        UserChallengeListQuery query,
        CancellationToken cancellationToken = default);

    Task<ChallengeParticipationStatusDto> GetParticipationStatusAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default);
}
