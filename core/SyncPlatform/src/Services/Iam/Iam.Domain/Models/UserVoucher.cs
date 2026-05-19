using Libs.Shared.Common;
using Iam.Domain.Enums;

namespace Iam.Domain.Models;

/// <summary>
/// A voucher/coupon owned by a user — treated as inventory (like UserAsset), not a financial transaction.
/// </summary>
public class UserVoucher : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public Guid? PromotionCampaignId { get; set; }

    public string VoucherCode { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string PromotionType { get; set; } = string.Empty;

    public decimal Value { get; set; }

    public VoucherStatus Status { get; set; }

    public DateTimeOffset AcquiredAt { get; set; }

    public DateTimeOffset? UsedAt { get; set; }

    public DateTimeOffset? ValidUntil { get; set; }
}
