using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class UserFollowRepository : IUserFollowRepository
{
    private readonly IMongoCollection<UserFollow> _collection;

    public UserFollowRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<UserFollow>("UserFollows");
    }

    public Task<UserFollow?> GetByPairAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, followerId),
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, followeeId));

        return _collection.Find(filter).FirstOrDefaultAsync(cancellationToken)!;
    }

    public async Task<bool> IsBlockedBetweenAsync(
        Guid userA,
        Guid userB,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Blocked),
            Builders<UserFollow>.Filter.Or(
                Builders<UserFollow>.Filter.And(
                    Builders<UserFollow>.Filter.Eq(x => x.FollowerId, userA),
                    Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, userB)),
                Builders<UserFollow>.Filter.And(
                    Builders<UserFollow>.Filter.Eq(x => x.FollowerId, userB),
                    Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, userA))));

        return await _collection.Find(filter).AnyAsync(cancellationToken);
    }

    public async Task<UserFollow> UpsertAsync(UserFollow entity, CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        entity.UpdatedAt = now;
        if (entity.CreatedAt == default)
            entity.CreatedAt = now;

        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, entity.FollowerId),
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, entity.FolloweeId));

        var existing = await _collection.Find(filter).FirstOrDefaultAsync(cancellationToken);
        if (existing is null)
        {
            await _collection.InsertOneAsync(entity, cancellationToken: cancellationToken);
            return entity;
        }

        entity.Id = existing.Id;
        entity.CreatedAt = existing.CreatedAt;
        await _collection.ReplaceOneAsync(filter, entity, cancellationToken: cancellationToken);
        return entity;
    }

    public async Task<bool> DeleteByPairAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, followerId),
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, followeeId));

        var result = await _collection.DeleteOneAsync(filter, cancellationToken);
        return result.DeletedCount > 0;
    }

    public async Task<(IReadOnlyList<UserFollow> Items, int TotalRecords)> GetFollowersAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, userId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return await GetPagedAsync(filter, pageNumber, pageSize, cancellationToken);
    }

    public async Task<(IReadOnlyList<UserFollow> Items, int TotalRecords)> GetFollowingAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, userId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return await GetPagedAsync(filter, pageNumber, pageSize, cancellationToken);
    }

    public async Task<int> CountFollowersAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, userId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
    }

    public async Task<int> CountFollowingAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, userId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
    }

    public async Task UpdateStatusAsync(
        Guid followerId,
        Guid followeeId,
        FollowStatus status,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, followerId),
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, followeeId));

        var update = Builders<UserFollow>.Update
            .Set(x => x.Status, status)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await _collection.UpdateOneAsync(filter, update, cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<Guid>> GetAcceptedFolloweeIdsAsync(
        Guid followerId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, followerId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return await _collection.Find(filter)
            .Project(x => x.FolloweeId)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Guid>> GetAcceptedFollowerIdsAsync(
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, followeeId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return await _collection.Find(filter)
            .Project(x => x.FollowerId)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> IsAcceptedFollowerAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.FollowerId, followerId),
            Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, followeeId),
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Accepted));

        return await _collection.Find(filter).AnyAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Guid>> GetBlockedPeerIdsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<UserFollow>.Filter.And(
            Builders<UserFollow>.Filter.Eq(x => x.Status, FollowStatus.Blocked),
            Builders<UserFollow>.Filter.Or(
                Builders<UserFollow>.Filter.Eq(x => x.FollowerId, userId),
                Builders<UserFollow>.Filter.Eq(x => x.FolloweeId, userId)));

        var follows = await _collection.Find(filter).ToListAsync(cancellationToken);
        return follows
            .Select(f => f.FollowerId == userId ? f.FolloweeId : f.FollowerId)
            .Distinct()
            .ToList();
    }

    private async Task<(IReadOnlyList<UserFollow> Items, int TotalRecords)> GetPagedAsync(
        FilterDefinition<UserFollow> filter,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await _collection.Find(filter)
            .SortByDescending(x => x.FollowedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }
}
