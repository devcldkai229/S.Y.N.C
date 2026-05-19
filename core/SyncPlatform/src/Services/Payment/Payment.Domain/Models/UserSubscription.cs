using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class UserSubscription : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public Guid SubscriptionPlanId { get; set; }

    public SubscriptionStatus Status { get; set; }

    public DateTimeOffset StartedAt { get; set; }

    public DateTimeOffset? ExpiredAt { get; set; }

    public bool AutoRenew { get; set; }

    public DateTimeOffset? LastBillingAt { get; set; }

    public DateTimeOffset? NextBillingAt { get; set; }

    public string? CancellationReason { get; set; }
}
