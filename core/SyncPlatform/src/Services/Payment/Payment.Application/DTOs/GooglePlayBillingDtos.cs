using System.ComponentModel.DataAnnotations;

namespace Payment.Application.DTOs;

public sealed class VerifyGooglePlayPurchaseRequest
{
    /// <summary>Play product / subscription ID (e.g. sync_premium_monthly).</summary>
    [Required]
    [MaxLength(128)]
    public string ProductId { get; set; } = string.Empty;

    /// <summary>Purchase token from Google Play Billing.</summary>
    [Required]
    [MaxLength(4096)]
    public string PurchaseToken { get; set; } = string.Empty;

    /// <summary>Optional SYNC plan id; if omitted, resolved via GooglePlayProductId.</summary>
    public Guid? PlanId { get; set; }
}

public sealed class VerifyGooglePlayPurchaseResponse
{
    public Guid UserSubscriptionId { get; set; }
    public Guid TransactionId { get; set; }
    public string Status { get; set; } = "Active";
    public DateTimeOffset? ExpiredAt { get; set; }
    public string Message { get; set; } = string.Empty;
}

public sealed class GooglePlayRtdnProcessResult
{
    public string Outcome { get; set; } = "Ignored";
    public string Message { get; set; } = string.Empty;
    public string? PurchaseToken { get; set; }
    public int? NotificationType { get; set; }
}
