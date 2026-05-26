using Social.Application.DTOs;

namespace Social.Application.Services;

public interface ICommunityChallengeService
{
    Task<CommunityChallengeDto> CreateAsync(
        Guid creatorId,
        CreateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CommunityChallengeDto>> GetActiveAsync(CancellationToken cancellationToken = default);
}
