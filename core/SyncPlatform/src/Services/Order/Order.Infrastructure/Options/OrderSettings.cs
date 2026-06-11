namespace Order.Infrastructure.Options;

public class OrderSettings
{
    public const string SectionName = "Order";

    public decimal DefaultDeliveryFee { get; set; } = 25000m;

    public int LocationPersistIntervalSeconds { get; set; } = 30;
}
