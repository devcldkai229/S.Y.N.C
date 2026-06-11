using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IBlogInteractionRepository
{
    Task<bool> TryCreateAsync(BlogInteraction interaction, CancellationToken cancellationToken = default);

    Task<bool> HasInteractionAsync(
        Guid blogId,
        Guid userId,
        InteractionType interactionType,
        CancellationToken cancellationToken = default);

    Task<HashSet<Guid>> GetLikedBlogIdsAsync(
        Guid userId,
        IEnumerable<Guid> blogIds,
        CancellationToken cancellationToken = default);
}
