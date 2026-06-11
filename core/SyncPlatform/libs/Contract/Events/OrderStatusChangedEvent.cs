namespace Contract.Events;

public class OrderStatusChangedEvent
{
    public Guid OrderId { get; set; }

    public Guid UserId { get; set; }

    public Guid PartnerId { get; set; }

    public string FromStatus { get; set; } = string.Empty;

    public string ToStatus { get; set; } = string.Empty;

    public string ChangedBy { get; set; } = string.Empty;

    public DateTimeOffset ChangedAt { get; set; }
}
