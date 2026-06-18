using Order.Domain.Enums;

namespace Order.Application.Ports;

public class DeliveryBookingRequest
{
    public Guid OrderId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public string PickupAddress { get; set; } = string.Empty;

    public decimal PickupLat { get; set; }

    public decimal PickupLng { get; set; }

    public string DeliveryAddress { get; set; } = string.Empty;

    public decimal DeliveryLat { get; set; }

    public decimal DeliveryLng { get; set; }

    public string RecipientName { get; set; } = string.Empty;

    public string RecipientPhone { get; set; } = string.Empty;
}

public class DeliveryBookingResult
{
    public bool Success { get; set; }

    public string? ExternalDeliveryId { get; set; }

    public string? ErrorMessage { get; set; }
}

public class DeliveryWebhookPayload
{
    public string EventId { get; set; } = string.Empty;

    public string EventType { get; set; } = string.Empty;

    public string? ExternalDeliveryId { get; set; }

    public string? Status { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public string? ShipperName { get; set; }

    public string? ShipperPhone { get; set; }

    public string? ShipperPlateNumber { get; set; }

    public string? SubStatus { get; set; }
}

public class DriverLocationRequest
{
    public string ExternalDeliveryId { get; set; } = string.Empty;

    public DeliveryStatus CurrentStatus { get; set; }

    public decimal? PickupLat { get; set; }

    public decimal? PickupLng { get; set; }

    public decimal? DeliveryLat { get; set; }

    public decimal? DeliveryLng { get; set; }

    public decimal? LastKnownLat { get; set; }

    public decimal? LastKnownLng { get; set; }

    public DateTimeOffset? AssignedAt { get; set; }

    public DateTimeOffset? PickedUpAt { get; set; }
}

public class DriverLocationResult
{
    public bool Found { get; set; }

    public decimal Latitude { get; set; }

    public decimal Longitude { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}

public interface IDeliveryProvider
{
    string ProviderName { get; }

    Task<DeliveryBookingResult> CreateOrderAsync(
        DeliveryBookingRequest request,
        CancellationToken cancellationToken = default);

    Task<DriverLocationResult?> GetDriverLocationAsync(
        DriverLocationRequest request,
        CancellationToken cancellationToken = default);

    DeliveryWebhookPayload? ParseAndVerifyWebhook(string rawBody, string? signatureHeader);
}
