using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class InteractionRepository : IInteractionRepository
{
    private readonly IMongoCollection<Interaction> _collection;

    public InteractionRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<Interaction>("Interactions");
    }

    public async Task<Interaction?> GetAsync(
        Guid postId,
        Guid userId,
        InteractionType interactionType,
        CancellationToken cancellationToken = default)
    {
        return await _collection
            .Find(x => x.PostId == postId && x.UserId == userId && x.InteractionType == interactionType)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task CreateAsync(Interaction interaction, CancellationToken cancellationToken = default)
    {
        interaction.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(interaction, cancellationToken: cancellationToken);
    }

    public async Task<bool> TryCreateAsync(Interaction interaction, CancellationToken cancellationToken = default)
    {
        try
        {
            await CreateAsync(interaction, cancellationToken);
            return true;
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            return false;
        }
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await _collection.DeleteOneAsync(x => x.Id == id, cancellationToken);
    }
}
