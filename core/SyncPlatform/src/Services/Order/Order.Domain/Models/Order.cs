using Libs.Shared.Common;
using Order.Domain.Enums;

namespace Order.Domain.Models;

public class Order : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public Guid PartnerId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public OrderStatus Status { get; set; }

    public decimal SubtotalAmount { get; set; }

    public decimal DeliveryFee { get; set; }

    public decimal DiscountAmount { get; set; }

    public decimal TotalAmount { get; set; }

    public string Currency { get; set; } = string.Empty;

    public Guid? PaymentTransactionId { get; set; }

    public PaymentStatus PaymentStatus { get; set; }

    public Guid? VoucherId { get; set; }

    public string? DeliveryAddress { get; set; }

    public decimal? DeliveryLat { get; set; }

    public decimal? DeliveryLng { get; set; }

    public string? RecipientName { get; set; }

    public string? RecipientPhone { get; set; }

    public string? Notes { get; set; }

    public bool IsAiInitiated { get; set; }

    public string? AIReasoningSnapshotJson { get; set; }

    public DateTimeOffset PlacedAt { get; set; }

    public DateTimeOffset? ConfirmedAt { get; set; }

    public DateTimeOffset? CompletedAt { get; set; }

    public DateTimeOffset? CancelledAt { get; set; }

    public string? CancellationReason { get; set; }

    public CancelledByType? CancelledBy { get; set; }

    public virtual ICollection<OrderItem> Items { get; set; } = [];
}
