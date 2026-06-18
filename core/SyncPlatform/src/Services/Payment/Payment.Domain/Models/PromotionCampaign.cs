using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class PromotionCampaign : BaseAuditableEntity
{
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public PromotionType PromotionType { get; set; }

    public decimal Value { get; set; }

    public decimal? MaxDiscountAmount { get; set; }

    public string? CouponCode { get; set; }

    public Guid? PartnerId { get; set; }

    public int PerUserUsageLimit { get; set; } = 1;

    public string? ApplicableProductTypesJson { get; set; }

    public decimal MinimumSpend { get; set; }

    public int UsageLimit { get; set; }

    public int UsageCount { get; set; }

    public DateTimeOffset StartsAt { get; set; }

    public DateTimeOffset EndsAt { get; set; }

    public bool IsActive { get; set; }
}
