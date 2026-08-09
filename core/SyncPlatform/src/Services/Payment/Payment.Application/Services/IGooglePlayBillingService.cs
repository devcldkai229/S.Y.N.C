using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IGooglePlayBillingService
{
    /// <summary>
    /// Verify a Play Billing purchaseToken with Google, activate/extend UserSubscription,
    /// sync IAM Premium, and acknowledge the purchase.
    /// </summary>
    Task<VerifyGooglePlayPurchaseResponse> VerifyPurchaseAsync(
        Guid userId,
        VerifyGooglePlayPurchaseRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Process a Real-time Developer Notification (Pub/Sub push body).
    /// </summary>
    Task<GooglePlayRtdnProcessResult> ProcessRtdnAsync(
        string rawJsonBody,
        CancellationToken cancellationToken = default);
}
