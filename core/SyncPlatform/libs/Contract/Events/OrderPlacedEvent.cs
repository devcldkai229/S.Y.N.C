namespace Contract.Events;

public class OrderPlacedEvent
{
    public Guid OrderId { get; set; }

    public Guid UserId { get; set; }

    public Guid PartnerId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public decimal TotalAmount { get; set; }

    public string Currency { get; set; } = string.Empty;

    public DateTimeOffset PlacedAt { get; set; }
}
