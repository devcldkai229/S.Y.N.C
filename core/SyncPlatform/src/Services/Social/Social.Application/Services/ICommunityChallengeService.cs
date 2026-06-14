using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface ICommunityChallengeService
{
    Task<CommunityChallengeDto> CreateAdminAsync(
        Guid creatorId,
        AdminCreateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default);

    Task<CommunityChallengeDto> UpdateAdminAsync(
        Guid challengeId,
        AdminUpdateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default);

    Task DeleteAdminAsync(Guid challengeId, CancellationToken cancellationToken = default);

    Task<CommunityChallengeDto> ActivateAsync(Guid challengeId, CancellationToken cancellationToken = default);

    Task<CommunityChallengeDto> CompleteAsync(Guid challengeId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<CommunityChallengeDto> Items, PaginationMetadata Pagination)> GetAdminPagedAsync(
        ChallengeAdminListQuery query,
        CancellationToken cancellationToken = default);

    Task<CommunityChallengeDto> GetAdminByIdAsync(Guid challengeId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<CommunityChallengeDto> Items, PaginationMetadata Pagination)> GetActivePagedAsync(
        ChallengePublicListQuery query,
        CancellationToken cancellationToken = default);

    Task<CommunityChallengeDto> GetActiveByIdAsync(Guid challengeId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<NearbyCommunityChallengeDto> Items, PaginationMetadata Pagination)> GetNearbyAsync(
        NearbyChallengeQuery query,
        CancellationToken cancellationToken = default);

    Task<ChallengeRouteDto> GetRouteAsync(
        Guid challengeId,
        ChallengeRouteQuery query,
        CancellationToken cancellationToken = default);
}
