namespace Social.Domain.Repositories;

public interface IStoryViewRepository
{
    /// <summary>
    /// Returns true when this is the first recorded view for (storyId, viewerId).
    /// </summary>
    Task<bool> TryRecordViewAsync(
        Guid storyId,
        Guid viewerId,
        CancellationToken cancellationToken = default);

    /// <summary>Story IDs among <paramref name="storyIds"/> that <paramref name="viewerId"/> has already viewed.</summary>
    Task<HashSet<Guid>> GetViewedStoryIdsAsync(
        Guid viewerId,
        IReadOnlyList<Guid> storyIds,
        CancellationToken cancellationToken = default);
}
