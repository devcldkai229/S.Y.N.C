using Libs.Shared.Common;
using Order.Domain.Enums;

namespace Order.Domain.Models;

public class CommissionRecord : BaseAuditableEntity
{
    public CommissionSource Source { get; set; }

    public Guid? OrderId { get; set; }

    public Guid PartnerId { get; set; }

    public Guid? RelatedProductId { get; set; }

    public string? ClickToken { get; set; }

    public string? ExternalReferenceId { get; set; }

    public decimal GrossAmount { get; set; }

    public decimal CommissionRate { get; set; }

    public decimal CommissionAmount { get; set; }

    public CommissionStatus Status { get; set; }

    public DateTimeOffset? ConfirmedAt { get; set; }

    public DateTimeOffset? PaidAt { get; set; }
}
