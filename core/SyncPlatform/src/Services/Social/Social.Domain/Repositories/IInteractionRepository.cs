using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IInteractionRepository
{
    Task<Interaction?> GetAsync(
        Guid postId,
        Guid userId,
        InteractionType interactionType,
        CancellationToken cancellationToken = default);

    Task CreateAsync(Interaction interaction, CancellationToken cancellationToken = default);

    /// <summary>Returns false when unique index blocks duplicate (PostId, UserId, InteractionType).</summary>
    Task<bool> TryCreateAsync(Interaction interaction, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
