using Microsoft.AspNetCore.SignalR;
using Roadmap.API.Hubs;
using Roadmap.Application.Services;

namespace Roadmap.API.Services;

public sealed class SignalRRoadmapRealtimePublisher : IRoadmapRealtimePublisher
{
    private readonly IHubContext<RoadmapHub> _hub;

    public SignalRRoadmapRealtimePublisher(IHubContext<RoadmapHub> hub) => _hub = hub;

    public Task PublishRoadmapUpdatedAsync(
        Guid userId,
        string kind,
        Guid? roadmapId = null,
        IReadOnlyList<Guid>? sessionIds = null,
        CancellationToken cancellationToken = default) =>
        _hub.Clients
            .Group(RoadmapHub.UserGroup(userId))
            .SendAsync(
                RoadmapHub.UpdatedEvent,
                new
                {
                    kind,
                    roadmapId = roadmapId?.ToString("D"),
                    sessionIds = sessionIds?.Select(id => id.ToString("D")).ToArray() ?? Array.Empty<string>(),
                },
                cancellationToken);
}
