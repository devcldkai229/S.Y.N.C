using Libs.Shared.Common;

namespace Order.Domain.Models;

public class OrderItem : BaseAuditableEntity
{
    public Guid OrderId { get; set; }

    public virtual Order Order { get; set; } = null!;

    public Guid FoodMenuItemId { get; set; }

    public string NameSnapshot { get; set; } = string.Empty;

    public string? ImageUrlSnapshot { get; set; }

    public decimal UnitPrice { get; set; }

    public int Quantity { get; set; }

    public decimal Subtotal { get; set; }

    public string? Notes { get; set; }
}
