using Microsoft.AspNetCore.SignalR;
using Order.API.Hubs;
using Order.Application.DTOs;
using Order.Application.Ports;

namespace Order.API.Services;

public class TrackingRealtimePublisher : ITrackingRealtimePublisher
{
    private readonly IHubContext<TrackingHub> _hubContext;
    private readonly ILogger<TrackingRealtimePublisher> _logger;

    public TrackingRealtimePublisher(
        IHubContext<TrackingHub> hubContext,
        ILogger<TrackingRealtimePublisher> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task PublishLocationAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default)
    {
        var group = TrackingHub.OrderGroup(update.OrderId);
        await _hubContext.Clients.Group(group).SendAsync(TrackingHub.LocationUpdateEvent, update, cancellationToken);
        await _hubContext.Clients.Group(group).SendAsync(TrackingHub.LocationUpdatedEvent, update, cancellationToken);

        _logger.LogInformation(
            "SignalR location published orderId={OrderId} group={Group} lat={Lat} lng={Lng}",
            update.OrderId,
            group,
            update.Latitude,
            update.Longitude);
    }

    public async Task PublishStatusAsync(TrackingStatusUpdateDto update, CancellationToken cancellationToken = default)
    {
        var group = TrackingHub.OrderGroup(update.OrderId);
        await _hubContext.Clients
            .Group(group)
            .SendAsync(TrackingHub.StatusUpdateEvent, update, cancellationToken);

        _logger.LogInformation(
            "SignalR status published orderId={OrderId} group={Group} orderStatus={OrderStatus} deliveryStatus={DeliveryStatus}",
            update.OrderId,
            group,
            update.OrderStatus,
            update.DeliveryStatus);
    }
}
