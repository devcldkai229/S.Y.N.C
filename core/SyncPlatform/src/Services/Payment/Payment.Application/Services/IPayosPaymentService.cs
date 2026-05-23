using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IPayosPaymentService
{
    /// <summary>
    /// Create a new PayOS payment link for the given subscription plan.
    /// Returns the checkout URL + QR code that the Flutter client renders.
    /// </summary>
    Task<CreatePaymentLinkResponse> CreatePaymentLinkAsync(
        Guid userId,
        CreatePaymentLinkRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Process a PayOS webhook callback. Verifies signature, applies idempotency,
    /// updates the Transaction + activates UserSubscription inside a DB transaction.
    /// </summary>
    /// <param name="rawJsonBody">The exact request body sent by PayOS (needed for signature verification).</param>
    Task<PayosWebhookProcessResult> ProcessWebhookAsync(
        string rawJsonBody,
        CancellationToken cancellationToken = default);
}
