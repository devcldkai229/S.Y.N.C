using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface ITrackingRealtimePublisher
{
    Task PublishLocationAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default);
}
