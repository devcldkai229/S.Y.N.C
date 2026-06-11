using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class StoryRepository : IStoryRepository
{
    private readonly IMongoCollection<Story> _collection;

    public StoryRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<Story>("Stories");
    }

    public Task<Story?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _collection.Find(x => x.Id == id).FirstOrDefaultAsync(cancellationToken)!;

    public async Task CreateAsync(Story story, CancellationToken cancellationToken = default)
    {
        story.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(story, cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<Story>> GetActiveByAuthorIdAsync(
        Guid authorId,
        DateTimeOffset now,
        CancellationToken cancellationToken = default)
    {
        var filter = ActiveFilter(authorId, now);
        return await _collection.Find(filter)
            .SortBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Story>> GetActiveByAuthorIdsAsync(
        IReadOnlyList<Guid> authorIds,
        DateTimeOffset now,
        CancellationToken cancellationToken = default)
    {
        if (authorIds.Count == 0)
            return [];

        var filter = Builders<Story>.Filter.And(
            Builders<Story>.Filter.In(x => x.AuthorId, authorIds),
            Builders<Story>.Filter.Eq(x => x.IsActive, true),
            Builders<Story>.Filter.Gt(x => x.ExpiresAt, now));

        return await _collection.Find(filter)
            .SortBy(x => x.AuthorId)
            .ThenBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> IncrementViewCountAsync(Guid storyId, CancellationToken cancellationToken = default)
    {
        var update = Builders<Story>.Update
            .Inc(x => x.ViewCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _collection.UpdateOneAsync(
            x => x.Id == storyId && x.IsActive,
            update,
            cancellationToken: cancellationToken);

        return result.ModifiedCount > 0;
    }

    public async Task<bool> IncrementLikeCountAsync(Guid storyId, CancellationToken cancellationToken = default)
    {
        var update = Builders<Story>.Update
            .Inc(x => x.LikeCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _collection.UpdateOneAsync(
            x => x.Id == storyId && x.IsActive,
            update,
            cancellationToken: cancellationToken);

        return result.ModifiedCount > 0;
    }

    public async Task<bool> SoftDeleteAsync(Guid storyId, Guid authorId, CancellationToken cancellationToken = default)
    {
        var update = Builders<Story>.Update
            .Set(x => x.IsActive, false)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _collection.UpdateOneAsync(
            x => x.Id == storyId && x.AuthorId == authorId && x.IsActive,
            update,
            cancellationToken: cancellationToken);

        return result.ModifiedCount > 0;
    }

    private static FilterDefinition<Story> ActiveFilter(Guid authorId, DateTimeOffset now) =>
        Builders<Story>.Filter.And(
            Builders<Story>.Filter.Eq(x => x.AuthorId, authorId),
            Builders<Story>.Filter.Eq(x => x.IsActive, true),
            Builders<Story>.Filter.Gt(x => x.ExpiresAt, now));
}
