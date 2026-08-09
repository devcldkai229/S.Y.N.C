namespace Payment.Application.Clients;

/// <summary>Thin wrapper around Google Play Android Publisher API.</summary>
public interface IGooglePlayAndroidPublisherClient
{
    bool IsConfigured { get; }

    /// <summary>
    /// GET purchases.subscriptionsv2 — returns null when the token is unknown/invalid.
    /// </summary>
    Task<GooglePlaySubscriptionInfo?> GetSubscriptionAsync(
        string packageName,
        string purchaseToken,
        CancellationToken cancellationToken = default);

    /// <summary>Acknowledge a subscription purchase (required within 3 days).</summary>
    Task AcknowledgeSubscriptionAsync(
        string packageName,
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default);
}

public sealed class GooglePlaySubscriptionInfo
{
    public string SubscriptionState { get; init; } = string.Empty;
    public DateTimeOffset? ExpiryTime { get; init; }
    public string? LatestOrderId { get; init; }
    public bool IsEntitlementActive { get; init; }
}
