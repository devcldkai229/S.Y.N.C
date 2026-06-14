using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IStoryRepository
{
    Task<Story?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task CreateAsync(Story story, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Story>> GetActiveByAuthorIdAsync(
        Guid authorId,
        DateTimeOffset now,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Story>> GetActiveByAuthorIdsAsync(
        IReadOnlyList<Guid> authorIds,
        DateTimeOffset now,
        CancellationToken cancellationToken = default);

    Task<bool> IncrementViewCountAsync(Guid storyId, CancellationToken cancellationToken = default);

    Task<bool> IncrementLikeCountAsync(Guid storyId, CancellationToken cancellationToken = default);

    Task<bool> SoftDeleteAsync(Guid storyId, Guid authorId, CancellationToken cancellationToken = default);
}
