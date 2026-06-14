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
}
