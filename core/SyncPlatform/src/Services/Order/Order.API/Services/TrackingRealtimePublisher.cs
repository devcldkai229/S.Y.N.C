using Microsoft.AspNetCore.SignalR;
using Order.API.Hubs;
using Order.Application.DTOs;
using Order.Application.Ports;

namespace Order.API.Services;

public class TrackingRealtimePublisher : ITrackingRealtimePublisher
{
    private readonly IHubContext<TrackingHub> _hubContext;

    public TrackingRealtimePublisher(IHubContext<TrackingHub> hubContext) => _hubContext = hubContext;

    public async Task PublishLocationAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default)
    {
        var group = TrackingHub.OrderGroup(update.OrderId);
        await _hubContext.Clients.Group(group).SendAsync(TrackingHub.LocationUpdateEvent, update, cancellationToken);
        await _hubContext.Clients.Group(group).SendAsync(TrackingHub.LocationUpdatedEvent, update, cancellationToken);
    }

    public Task PublishStatusAsync(TrackingStatusUpdateDto update, CancellationToken cancellationToken = default) =>
        _hubContext.Clients
            .Group(TrackingHub.OrderGroup(update.OrderId))
            .SendAsync(TrackingHub.StatusUpdateEvent, update, cancellationToken);
}
