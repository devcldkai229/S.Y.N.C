using Order.Domain.Enums;

namespace Order.Application.DTOs;

public class CommissionRecordDto
{
    public Guid Id { get; set; }

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

    public DateTimeOffset CreatedAt { get; set; }
}

public class AffiliateReconcileLineDto
{
    public string ExternalReferenceId { get; set; } = string.Empty;

    public string? ClickToken { get; set; }

    public Guid PartnerId { get; set; }

    public Guid RelatedProductId { get; set; }

    public decimal GrossAmount { get; set; }

    public decimal CommissionRate { get; set; }

    public decimal CommissionAmount { get; set; }
}

public class AffiliateReconcileRequest
{
    public List<AffiliateReconcileLineDto> Lines { get; set; } = [];
}

public class CommissionListRequest
{
    public CommissionSource? Source { get; set; }

    public Guid? PartnerId { get; set; }

    public CommissionStatus? Status { get; set; }

    public DateTimeOffset? From { get; set; }

    public DateTimeOffset? To { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class CommissionRevenueSummaryDto
{
    public decimal TotalGross { get; set; }

    public decimal TotalCommission { get; set; }

    public int RecordCount { get; set; }
}

public class MarkCommissionPaidDto
{
    public DateTimeOffset? PaidAt { get; set; }
}
