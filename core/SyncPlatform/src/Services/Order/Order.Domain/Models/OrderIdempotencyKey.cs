using Libs.Shared.Common;

namespace Order.Domain.Models;

public class OrderIdempotencyKey : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public string ClientRequestKey { get; set; } = string.Empty;

    public Guid OrderId { get; set; }
}
