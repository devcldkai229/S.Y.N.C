using Libs.Shared.Common;
using Order.Domain.Enums;

namespace Order.Domain.Models;

public class OrderStatusHistory : BaseAuditableEntity
{
    public Guid OrderId { get; set; }

    public virtual Order Order { get; set; } = null!;

    public OrderStatus? FromStatus { get; set; }

    public OrderStatus ToStatus { get; set; }

    public string ChangedBy { get; set; } = string.Empty;

    public string? Note { get; set; }
}
