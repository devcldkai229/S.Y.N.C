using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class ChallengeParticipantRepository : IChallengeParticipantRepository
{
    private readonly IMongoCollection<ChallengeParticipant> _collection;

    public ChallengeParticipantRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<ChallengeParticipant>("ChallengeParticipants");
    }

    public Task<ChallengeParticipant?> GetByChallengeAndUserAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default) =>
        _collection.Find(x => x.ChallengeId == challengeId && x.UserId == userId)
            .FirstOrDefaultAsync(cancellationToken)!;

    public async Task<IReadOnlyList<Guid>> GetActiveParticipantUserIdsAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        return await _collection.Find(x => x.ChallengeId == challengeId && x.IsActive)
            .Project(x => x.UserId)
            .ToListAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<ChallengeParticipant> Items, int TotalRecords)> GetPagedByChallengeAsync(
        Guid challengeId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<ChallengeParticipant>.Filter.Eq(x => x.ChallengeId, challengeId);
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await _collection.Find(filter)
            .SortByDescending(x => x.JoinedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<(IReadOnlyList<ChallengeParticipant> Items, int TotalRecords)> GetPagedByUserAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<ChallengeParticipant>.Filter.And(
            Builders<ChallengeParticipant>.Filter.Eq(x => x.UserId, userId),
            Builders<ChallengeParticipant>.Filter.Eq(x => x.IsActive, true));

        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await _collection.Find(filter)
            .SortByDescending(x => x.JoinedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<bool> UpdateStatusAsync(
        Guid challengeId,
        Guid userId,
        ParticipantStatus expectedCurrentStatus,
        ParticipantStatus newStatus,
        DateTimeOffset? completedAt = null,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<ChallengeParticipant>.Update
            .Set(x => x.Status, newStatus)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        if (completedAt.HasValue)
            update = update.Set(x => x.CompletedAt, completedAt.Value);

        var result = await _collection.UpdateOneAsync(
            x => x.ChallengeId == challengeId &&
                 x.UserId == userId &&
                 x.IsActive &&
                 x.Status == expectedCurrentStatus,
            update,
            cancellationToken: cancellationToken);

        return result.ModifiedCount > 0;
    }
}
