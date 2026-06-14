using Libs.Shared.Common;

namespace Payment.Domain.Models;

public class UserVoucher : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public Guid PromotionCampaignId { get; set; }

    public virtual PromotionCampaign? PromotionCampaign { get; set; }

    public bool IsUsed { get; set; }

    public DateTimeOffset? UsedAt { get; set; }

    public Guid? UsedOnOrderId { get; set; }
}
