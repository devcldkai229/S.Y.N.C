using Microsoft.AspNetCore.SignalR;
using Order.API.Hubs;
using Order.Application.DTOs;
using Order.Application.Ports;

namespace Order.API.Services;

public class TrackingRealtimePublisher : ITrackingRealtimePublisher
{
    private readonly IHubContext<TrackingHub> _hubContext;

    public TrackingRealtimePublisher(IHubContext<TrackingHub> hubContext) => _hubContext = hubContext;

    public Task PublishLocationAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default) =>
        _hubContext.Clients
            .Group(TrackingHub.OrderGroup(update.OrderId))
            .SendAsync(TrackingHub.LocationUpdatedEvent, update, cancellationToken);
}
