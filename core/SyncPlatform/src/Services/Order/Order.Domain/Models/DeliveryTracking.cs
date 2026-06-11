using Libs.Shared.Common;
using Order.Domain.Enums;

namespace Order.Domain.Models;

public class DeliveryTracking : BaseAuditableEntity
{
    public Guid OrderId { get; set; }

    public virtual Order Order { get; set; } = null!;

    public string Provider { get; set; } = string.Empty;

    public string? ExternalDeliveryId { get; set; }

    public string? ShipperName { get; set; }

    public string? ShipperPhone { get; set; }

    public string? ShipperPlateNumber { get; set; }

    public DeliveryStatus Status { get; set; }

    public decimal? LastKnownLat { get; set; }

    public decimal? LastKnownLng { get; set; }

    public DateTimeOffset? LastLocationUpdatedAt { get; set; }

    public DateTimeOffset? EstimatedArrivalAt { get; set; }

    public DateTimeOffset? AssignedAt { get; set; }

    public DateTimeOffset? PickedUpAt { get; set; }

    public DateTimeOffset? DeliveredAt { get; set; }
}
