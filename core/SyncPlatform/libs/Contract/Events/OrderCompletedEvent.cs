namespace Contract.Events;

public class OrderCompletedEvent
{
    public Guid OrderId { get; set; }

    public Guid UserId { get; set; }

    public DateTimeOffset CompletedAt { get; set; }

    public List<OrderCompletedLineItem> Items { get; set; } = [];
}

public class OrderCompletedLineItem
{
    public Guid FoodMenuItemId { get; set; }

    public string NameSnapshot { get; set; } = string.Empty;

    public int Quantity { get; set; }

    public int Calories { get; set; }

    public decimal ProteinGram { get; set; }

    public decimal CarbGram { get; set; }

    public decimal FatGram { get; set; }
}
