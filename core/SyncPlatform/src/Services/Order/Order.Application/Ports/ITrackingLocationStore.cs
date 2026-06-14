using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface ITrackingLocationStore
{
    Task SetLiveLocationAsync(Guid orderId, decimal lat, decimal lng, TimeSpan ttl, CancellationToken cancellationToken = default);

    Task<TrackingLocationUpdateDto?> GetLiveLocationAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task PublishLocationUpdateAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default);
}
