using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class CommunityChallengeRepository : GenericRepository<CommunityChallenge>, ICommunityChallengeRepository
{
    public CommunityChallengeRepository(IMongoDatabase database)
        : base(database, "CommunityChallenges")
    {
    }

    public async Task<IReadOnlyList<CommunityChallenge>> GetActiveAsync(
        CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        var filter = Builders<CommunityChallenge>.Filter.And(
            Builders<CommunityChallenge>.Filter.Eq(x => x.Status, ChallengeStatus.Active),
            Builders<CommunityChallenge>.Filter.Lte(x => x.StartDate, now),
            Builders<CommunityChallenge>.Filter.Gte(x => x.EndDate, now));

        return await Collection.Find(filter)
            .SortBy(x => x.EndDate)
            .ToListAsync(cancellationToken);
    }

    public async Task RefreshStatusAsync(
        Guid id,
        ChallengeStatus status,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<CommunityChallenge>.Update
            .Set(x => x.Status, status)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }
}
