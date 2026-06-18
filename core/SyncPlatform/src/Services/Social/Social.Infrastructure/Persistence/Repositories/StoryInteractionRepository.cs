using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class StoryInteractionRepository : IStoryInteractionRepository
{
    private readonly IMongoCollection<StoryInteraction> _collection;

    public StoryInteractionRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<StoryInteraction>("StoryInteractions");
    }

    public async Task<bool> TryCreateAsync(
        StoryInteraction interaction,
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

    public async Task<bool> HasLikedAsync(
        Guid storyId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        return await _collection.Find(x =>
                x.StoryId == storyId &&
                x.UserId == userId &&
                x.InteractionType == InteractionType.Like)
            .AnyAsync(cancellationToken);
    }
}
