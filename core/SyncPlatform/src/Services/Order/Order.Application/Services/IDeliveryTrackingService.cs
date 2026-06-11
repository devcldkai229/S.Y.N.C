using Order.Application.DTOs;
using Order.Application.Ports;

namespace Order.Application.Services;

public interface IDeliveryTrackingService
{
    Task BookDeliveryAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task<DeliveryTrackingDto?> GetTrackingAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task ProcessWebhookAsync(DeliveryWebhookPayload payload, string rawPayloadJson, CancellationToken cancellationToken = default);
}
