using System.Text;
using Google.Apis.AndroidPublisher.v3;
using Google.Apis.AndroidPublisher.v3.Data;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Payment.Application.Clients;
using Payment.Application.Options;

namespace Payment.Infrastructure.Clients;

public sealed class GooglePlayAndroidPublisherClient : IGooglePlayAndroidPublisherClient, IDisposable
{
    private readonly GooglePlaySettings _settings;
    private readonly ILogger<GooglePlayAndroidPublisherClient> _logger;
    private readonly AndroidPublisherService? _service;
    private readonly object _gate = new();

    public GooglePlayAndroidPublisherClient(
        IOptions<GooglePlaySettings> settings,
        ILogger<GooglePlayAndroidPublisherClient> logger)
    {
        _settings = settings.Value;
        _logger = logger;
        _service = TryCreateService();
    }

    public bool IsConfigured => _service is not null;

    public async Task<GooglePlaySubscriptionInfo?> GetSubscriptionAsync(
        string packageName,
        string purchaseToken,
        CancellationToken cancellationToken = default)
    {
        if (_service is null)
            throw new InvalidOperationException("Google Play Android Publisher client is not configured.");

        try
        {
            var purchase = await _service.Purchases.Subscriptionsv2
                .Get(packageName, purchaseToken)
                .ExecuteAsync(cancellationToken);

            var lineItem = purchase.LineItems?.FirstOrDefault();
            DateTimeOffset? expiry = lineItem?.ExpiryTimeDateTimeOffset;

            var state = purchase.SubscriptionState ?? string.Empty;
            var active = state is "SUBSCRIPTION_STATE_ACTIVE"
                or "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
                or "SUBSCRIPTION_STATE_CANCELED"; // canceled but still entitled until expiry

            // Canceled still entitled only if expiry in future
            if (state == "SUBSCRIPTION_STATE_CANCELED" && expiry is { } exp && exp <= DateTimeOffset.UtcNow)
                active = false;

            return new GooglePlaySubscriptionInfo
            {
                SubscriptionState = state,
                ExpiryTime = expiry,
                LatestOrderId = purchase.LatestOrderId,
                IsEntitlementActive = active
                    || (expiry is { } e && e > DateTimeOffset.UtcNow
                        && state is not "SUBSCRIPTION_STATE_EXPIRED"
                            and not "SUBSCRIPTION_STATE_REVOKED"),
            };
        }
        catch (Google.GoogleApiException ex) when (ex.HttpStatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger.LogWarning("Google Play subscription token not found for package {Package}", packageName);
            return null;
        }
    }

    public async Task AcknowledgeSubscriptionAsync(
        string packageName,
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default)
    {
        if (_service is null)
            throw new InvalidOperationException("Google Play Android Publisher client is not configured.");

        try
        {
            var body = new SubscriptionPurchasesAcknowledgeRequest();
            await _service.Purchases.Subscriptions
                .Acknowledge(body, packageName, productId, purchaseToken)
                .ExecuteAsync(cancellationToken);
        }
        catch (Google.GoogleApiException ex) when (
            ex.HttpStatusCode == System.Net.HttpStatusCode.BadRequest
            && (ex.Message?.Contains("already", StringComparison.OrdinalIgnoreCase) ?? false))
        {
            // Already acknowledged — treat as success.
            _logger.LogInformation(
                "Google Play purchase already acknowledged. ProductId={ProductId}", productId);
        }
    }

    private AndroidPublisherService? TryCreateService()
    {
        var raw = _settings.ServiceAccountJson?.Trim();
        if (string.IsNullOrWhiteSpace(raw))
        {
            _logger.LogWarning(
                "GooglePlay:ServiceAccountJson is empty — Play verify/RTDN will require DevSimulateVerify or configuration.");
            return null;
        }

        try
        {
            GoogleCredential credential;
            if (raw.StartsWith('{'))
            {
                using var stream = new MemoryStream(Encoding.UTF8.GetBytes(raw));
                credential = GoogleCredential.FromStream(stream)
                    .CreateScoped(AndroidPublisherService.Scope.Androidpublisher);
            }
            else if (File.Exists(raw))
            {
                credential = GoogleCredential.FromFile(raw)
                    .CreateScoped(AndroidPublisherService.Scope.Androidpublisher);
            }
            else
            {
                _logger.LogError(
                    "GooglePlay:ServiceAccountJson is neither JSON nor an existing file path.");
                return null;
            }

            return new AndroidPublisherService(new BaseClientService.Initializer
            {
                HttpClientInitializer = credential,
                ApplicationName = "SYNC-Payment",
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Google Play Android Publisher client.");
            return null;
        }
    }

    public void Dispose()
    {
        lock (_gate)
        {
            _service?.Dispose();
        }
    }
}
