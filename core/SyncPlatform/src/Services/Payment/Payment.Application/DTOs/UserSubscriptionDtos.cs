using System.ComponentModel.DataAnnotations;
using Payment.Domain.Enums;

namespace Payment.Application.DTOs;

public class UserSubscriptionDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid SubscriptionPlanId { get; set; }
    public string SubscriptionPlanName { get; set; } = string.Empty;
    public SubscriptionStatus Status { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? ExpiredAt { get; set; }
    public bool AutoRenew { get; set; }
    public DateTimeOffset? LastBillingAt { get; set; }
    public DateTimeOffset? NextBillingAt { get; set; }
    public string? CancellationReason { get; set; }
    public PaymentProvider ManagedBy { get; set; }
    public string? ExternalSubscriptionId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreateUserSubscriptionDto
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    public Guid SubscriptionPlanId { get; set; }

    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Active;

    public DateTimeOffset StartedAt { get; set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset? ExpiredAt { get; set; }

    public bool AutoRenew { get; set; } = false;

    public DateTimeOffset? LastBillingAt { get; set; }

    public DateTimeOffset? NextBillingAt { get; set; }

    public PaymentProvider ManagedBy { get; set; } = PaymentProvider.InternalWallet;

    [MaxLength(256)]
    public string? ExternalSubscriptionId { get; set; }
}

public class UpdateUserSubscriptionDto
{
    public SubscriptionStatus Status { get; set; }

    public DateTimeOffset? ExpiredAt { get; set; }

    public bool AutoRenew { get; set; }

    public DateTimeOffset? LastBillingAt { get; set; }

    public DateTimeOffset? NextBillingAt { get; set; }

    [MaxLength(512)]
    public string? CancellationReason { get; set; }

    public PaymentProvider ManagedBy { get; set; }

    [MaxLength(256)]
    public string? ExternalSubscriptionId { get; set; }
}

public class CancelSubscriptionRequest
{
    [MaxLength(512)]
    public string? CancellationReason { get; set; }
}
