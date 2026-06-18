using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class StoryViewRepository : IStoryViewRepository
{
    private readonly IMongoCollection<StoryView> _collection;

    public StoryViewRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<StoryView>("StoryViews");
    }

    public async Task<bool> TryRecordViewAsync(
        Guid storyId,
        Guid viewerId,
        CancellationToken cancellationToken = default)
    {
        var view = new StoryView
        {
            StoryId = storyId,
            ViewerId = viewerId,
            ViewedAt = DateTimeOffset.UtcNow,
        };

        try
        {
            await _collection.InsertOneAsync(view, cancellationToken: cancellationToken);
            return true;
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            return false;
        }
    }
}
