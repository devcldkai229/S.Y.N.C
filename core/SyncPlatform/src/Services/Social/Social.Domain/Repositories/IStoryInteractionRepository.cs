using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IStoryInteractionRepository
{
    Task<bool> TryCreateAsync(StoryInteraction interaction, CancellationToken cancellationToken = default);

    Task<bool> HasLikedAsync(Guid storyId, Guid userId, CancellationToken cancellationToken = default);
}
