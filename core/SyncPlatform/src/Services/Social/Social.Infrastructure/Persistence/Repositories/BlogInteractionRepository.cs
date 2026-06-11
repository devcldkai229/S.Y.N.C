using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class BlogInteractionRepository : IBlogInteractionRepository
{
    private readonly IMongoCollection<BlogInteraction> _collection;

    public BlogInteractionRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<BlogInteraction>("BlogInteractions");
    }

    public async Task<bool> TryCreateAsync(
        BlogInteraction interaction,
        CancellationToken cancellationToken = default)
    {
        interaction.CreatedAt = DateTimeOffset.UtcNow;

        try
        {
            await _collection.InsertOneAsync(interaction, cancellationToken: cancellationToken);
            return true;
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            return false;
        }
    }

    public async Task<bool> HasInteractionAsync(
        Guid blogId,
        Guid userId,
        InteractionType interactionType,
        CancellationToken cancellationToken = default)
    {
        return await _collection.Find(x =>
                x.BlogId == blogId &&
                x.UserId == userId &&
                x.InteractionType == interactionType)
            .AnyAsync(cancellationToken);
    }

    public async Task<HashSet<Guid>> GetLikedBlogIdsAsync(
        Guid userId,
        IEnumerable<Guid> blogIds,
        CancellationToken cancellationToken = default)
    {
        var ids = blogIds.Distinct().ToList();
        if (ids.Count == 0)
            return [];

        var filter = Builders<BlogInteraction>.Filter.And(
            Builders<BlogInteraction>.Filter.Eq(x => x.UserId, userId),
            Builders<BlogInteraction>.Filter.Eq(x => x.InteractionType, InteractionType.Like),
            Builders<BlogInteraction>.Filter.In(x => x.BlogId, ids));

        var likedIds = await _collection.Find(filter)
            .Project(x => x.BlogId)
            .ToListAsync(cancellationToken);

        return likedIds.ToHashSet();
    }
}
