using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class PromotionCampaign : BaseAuditableEntity
{
    public string Name { get; set; } = string.Empty;

    public PromotionType PromotionType { get; set; }

    public decimal Value { get; set; }

    public string? CouponCode { get; set; }

    public string? ApplicableProductTypesJson { get; set; }

    public decimal MinimumSpend { get; set; }

    public int UsageLimit { get; set; }

    public DateTimeOffset StartsAt { get; set; }

    public DateTimeOffset EndsAt { get; set; }

    public bool IsActive { get; set; }
}
