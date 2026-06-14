namespace Payment.Application.DTOs;

public class VoucherAvailableItemDto
{
    public string Code { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string DiscountType { get; set; } = string.Empty;

    public decimal DiscountValue { get; set; }

    public decimal MinOrderAmount { get; set; }

    public decimal? MaxDiscount { get; set; }

    public DateTimeOffset ValidUntil { get; set; }

    public decimal EstimatedDiscount { get; set; }

    public bool Eligible { get; set; }

    public string? IneligibleReason { get; set; }

    public Guid CampaignId { get; set; }

    public Guid? UserVoucherId { get; set; }
}

public class ValidateVoucherRequestDto
{
    public string Code { get; set; } = string.Empty;

    public decimal OrderAmount { get; set; }

    public Guid? PartnerId { get; set; }
}

public class ValidateVoucherResponseDto
{
    public bool Valid { get; set; }

    public decimal DiscountAmount { get; set; }

    public Guid? VoucherId { get; set; }

    public Guid? CampaignId { get; set; }

    public string? Message { get; set; }
}

public class MarkVoucherUsedRequestDto
{
    public Guid UserId { get; set; }

    public string Code { get; set; } = string.Empty;

    public Guid OrderId { get; set; }
}
