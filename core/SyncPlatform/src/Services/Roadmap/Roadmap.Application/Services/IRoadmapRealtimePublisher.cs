namespace Roadmap.Application.Services;

public interface IRoadmapRealtimePublisher
{
    Task PublishRoadmapUpdatedAsync(
        Guid userId,
        string kind,
        Guid? roadmapId = null,
        IReadOnlyList<Guid>? sessionIds = null,
        CancellationToken cancellationToken = default);
}

public sealed class NoOpRoadmapRealtimePublisher : IRoadmapRealtimePublisher
{
    public Task PublishRoadmapUpdatedAsync(
        Guid userId,
        string kind,
        Guid? roadmapId = null,
        IReadOnlyList<Guid>? sessionIds = null,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
