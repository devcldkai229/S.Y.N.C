using Order.Domain.Enums;

namespace Order.Application.DTOs;

public class DeliveryTrackingDto
{
    public Guid OrderId { get; set; }

    public string Provider { get; set; } = string.Empty;

    public string? ExternalDeliveryId { get; set; }

    public string? ShipperName { get; set; }

    public string? ShipperPhone { get; set; }

    public string? ShipperPlateNumber { get; set; }

    public DeliveryStatus Status { get; set; }

    public OrderStatus? OrderStatus { get; set; }

    public int? EtaMinutes { get; set; }

    public decimal? PickupLat { get; set; }

    public decimal? PickupLng { get; set; }

    public decimal? LastKnownLat { get; set; }

    public decimal? LastKnownLng { get; set; }

    public DateTimeOffset? LastLocationUpdatedAt { get; set; }

    public DateTimeOffset? EstimatedArrivalAt { get; set; }

    public string? StatusMessage { get; set; }
}

public class TrackingLocationUpdateDto
{
    public Guid OrderId { get; set; }

    public decimal Latitude { get; set; }

    public decimal Longitude { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}

public class TrackingStatusUpdateDto
{
    public Guid OrderId { get; set; }

    public OrderStatus? OrderStatus { get; set; }

    public DeliveryStatus DeliveryStatus { get; set; }

    public int? EtaMinutes { get; set; }

    public string? ShipperName { get; set; }

    public string? ShipperPhone { get; set; }

    public string? ShipperPlateNumber { get; set; }

    public string? StatusMessage { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}
