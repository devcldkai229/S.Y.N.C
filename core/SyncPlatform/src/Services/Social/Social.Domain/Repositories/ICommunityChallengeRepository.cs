using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface ICommunityChallengeRepository : IGenericRepository<CommunityChallenge>
{
    Task<IReadOnlyList<CommunityChallenge>> GetActiveAsync(CancellationToken cancellationToken = default);

    Task RefreshStatusAsync(Guid id, ChallengeStatus status, CancellationToken cancellationToken = default);
}
