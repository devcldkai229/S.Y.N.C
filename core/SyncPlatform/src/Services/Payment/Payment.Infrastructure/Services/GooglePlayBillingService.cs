using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Payment.Application.Clients;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Options;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public sealed class GooglePlayBillingService : IGooglePlayBillingService
{
    private const string ProviderName = "GooglePlay";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly PaymentDbContext _db;
    private readonly GooglePlaySettings _settings;
    private readonly IGooglePlayAndroidPublisherClient _playClient;
    private readonly IIamSubscriptionClient _iamClient;
    private readonly ILogger<GooglePlayBillingService> _logger;

    public GooglePlayBillingService(
        PaymentDbContext db,
        IOptions<GooglePlaySettings> settings,
        IGooglePlayAndroidPublisherClient playClient,
        IIamSubscriptionClient iamClient,
        ILogger<GooglePlayBillingService> logger)
    {
        _db = db;
        _settings = settings.Value;
        _playClient = playClient;
        _iamClient = iamClient;
        _logger = logger;
    }

    public async Task<VerifyGooglePlayPurchaseResponse> VerifyPurchaseAsync(
        Guid userId,
        VerifyGooglePlayPurchaseRequest request,
        CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            throw new UnauthorizedException("User is not authenticated.");
        if (string.IsNullOrWhiteSpace(request.ProductId))
            throw new BadRequestException("ProductId is required.");
        if (string.IsNullOrWhiteSpace(request.PurchaseToken))
            throw new BadRequestException("PurchaseToken is required.");

        var productId = request.ProductId.Trim();
        var purchaseToken = request.PurchaseToken.Trim();

        var plan = await ResolvePlanAsync(request.PlanId, productId, cancellationToken);

        // Idempotent: same token already linked
        var existingByToken = await _db.UserSubscriptions
            .Where(s => s.ExternalSubscriptionId == purchaseToken && s.ManagedBy == PaymentProvider.GooglePlay)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (existingByToken is not null)
        {
            if (existingByToken.UserId != userId)
                throw new BadRequestException("This Google Play purchase is already linked to another account.");

            if (existingByToken.Status == SubscriptionStatus.Active
                && (existingByToken.ExpiredAt is null || existingByToken.ExpiredAt > DateTimeOffset.UtcNow))
            {
                await SyncTierToIamAsync(userId, "Premium", cancellationToken);
                return new VerifyGooglePlayPurchaseResponse
                {
                    UserSubscriptionId = existingByToken.Id,
                    TransactionId = Guid.Empty,
                    Status = existingByToken.Status.ToString(),
                    ExpiredAt = existingByToken.ExpiredAt,
                    Message = "Purchase already verified.",
                };
            }
        }

        DateTimeOffset? expiry;
        string? orderId = null;
        string rawPayload;

        if (_settings.DevSimulateVerify && !_playClient.IsConfigured)
        {
            _logger.LogWarning(
                "GooglePlay DevSimulateVerify: trusting client token without Google API. UserId={UserId}",
                userId);
            expiry = DateTimeOffset.UtcNow.AddDays(_settings.MonthlyDurationDays);
            rawPayload = JsonSerializer.Serialize(new { mode = "DevSimulate", productId, purchaseToken });
        }
        else
        {
            if (!_playClient.IsConfigured)
                throw new BadRequestException(
                    "Google Play Billing is not configured on the server (missing ServiceAccountJson).");

            var info = await _playClient.GetSubscriptionAsync(
                _settings.PackageName, purchaseToken, cancellationToken)
                ?? throw new BadRequestException("Google Play purchase token is invalid or unknown.");

            if (!info.IsEntitlementActive)
                throw new BadRequestException(
                    $"Google Play subscription is not active (state={info.SubscriptionState}).");

            expiry = info.ExpiryTime
                     ?? DateTimeOffset.UtcNow.AddDays(_settings.MonthlyDurationDays);
            orderId = info.LatestOrderId;
            rawPayload = JsonSerializer.Serialize(info, JsonOptions);

            try
            {
                await _playClient.AcknowledgeSubscriptionAsync(
                    _settings.PackageName, productId, purchaseToken, cancellationToken);
            }
            catch (Exception ex)
            {
                // Still activate entitlement; acknowledge can be retried via RTDN.
                _logger.LogWarning(ex,
                    "Failed to acknowledge Google Play purchase. ProductId={ProductId}", productId);
            }
        }

        var now = DateTimeOffset.UtcNow;
        var orderCode = (now.ToUnixTimeMilliseconds() * 1000) + Random.Shared.Next(0, 1000);

        var transaction = new Transaction
        {
            UserId = userId,
            TransactionType = TransactionType.Subscription,
            Status = TransactionStatus.Succeeded,
            PaymentMethod = PaymentMethod.GooglePlay,
            Provider = PaymentProvider.GooglePlay,
            Amount = plan.MonthlyPrice,
            Currency = plan.Currency,
            OrderCode = orderCode,
            ExternalReferenceId = orderId ?? purchaseToken,
            RelatedEntityType = nameof(SubscriptionPlan),
            RelatedEntityId = plan.Id,
            Description = $"SYNC {plan.Name} (Google Play)",
            SpendingAuthorizationType = SpendingAuthorizationType.ManualApproval,
            ProcessedAt = now,
            RawProviderPayload = rawPayload,
        };
        _db.Transactions.Add(transaction);

        var sub = await ActivateOrExtendAsync(
            userId, plan.Id, purchaseToken, expiry ?? now.AddDays(_settings.MonthlyDurationDays), now, cancellationToken);

        await _db.SaveChangesAsync(cancellationToken);
        await SyncTierToIamAsync(userId, "Premium", cancellationToken);

        return new VerifyGooglePlayPurchaseResponse
        {
            UserSubscriptionId = sub.Id,
            TransactionId = transaction.Id,
            Status = sub.Status.ToString(),
            ExpiredAt = sub.ExpiredAt,
            Message = "Google Play purchase verified and Premium activated.",
        };
    }

    public async Task<GooglePlayRtdnProcessResult> ProcessRtdnAsync(
        string rawJsonBody,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(rawJsonBody))
            throw new BadRequestException("RTDN body is empty.");

        PubSubPushEnvelope? envelope;
        try
        {
            envelope = JsonSerializer.Deserialize<PubSubPushEnvelope>(rawJsonBody, JsonOptions);
        }
        catch (JsonException ex)
        {
            throw new BadRequestException($"Invalid RTDN JSON: {ex.Message}");
        }

        if (envelope?.Message?.Data is null)
            throw new BadRequestException("RTDN message.data is missing.");

        var externalEventId = envelope.Message.MessageId
                              ?? Convert.ToBase64String(Encoding.UTF8.GetBytes(envelope.Message.Data))[..Math.Min(64, envelope.Message.Data.Length)];

        var already = await _db.PaymentWebhookEvents
            .AsNoTracking()
            .AnyAsync(e => e.Provider == ProviderName && e.ExternalEventId == externalEventId && e.Processed,
                cancellationToken);
        if (already)
        {
            return new GooglePlayRtdnProcessResult
            {
                Outcome = "Duplicate",
                Message = "RTDN already processed.",
            };
        }

        string decodedJson;
        try
        {
            decodedJson = Encoding.UTF8.GetString(Convert.FromBase64String(envelope.Message.Data));
        }
        catch (FormatException)
        {
            throw new BadRequestException("RTDN message.data is not valid base64.");
        }

        DeveloperNotification? notification;
        try
        {
            notification = JsonSerializer.Deserialize<DeveloperNotification>(decodedJson, JsonOptions);
        }
        catch (JsonException ex)
        {
            throw new BadRequestException($"Invalid DeveloperNotification JSON: {ex.Message}");
        }

        var webhookEvent = new PaymentWebhookEvent
        {
            Provider = ProviderName,
            EventType = "RTDN",
            ExternalEventId = externalEventId,
            PayloadJson = decodedJson,
            Processed = false,
            RetryCount = 0,
        };
        _db.PaymentWebhookEvents.Add(webhookEvent);

        var subNotif = notification?.SubscriptionNotification;
        if (subNotif is null || string.IsNullOrWhiteSpace(subNotif.PurchaseToken))
        {
            webhookEvent.Processed = true;
            webhookEvent.ProcessedAt = DateTimeOffset.UtcNow;
            webhookEvent.ErrorMessage = "No subscriptionNotification — ignored.";
            await _db.SaveChangesAsync(cancellationToken);
            return new GooglePlayRtdnProcessResult
            {
                Outcome = "Ignored",
                Message = "Not a subscription notification.",
            };
        }

        var purchaseToken = subNotif.PurchaseToken.Trim();
        var productId = subNotif.SubscriptionId?.Trim() ?? string.Empty;
        var notifType = subNotif.NotificationType;

        var userSub = await _db.UserSubscriptions
            .Where(s => s.ExternalSubscriptionId == purchaseToken && s.ManagedBy == PaymentProvider.GooglePlay)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var now = DateTimeOffset.UtcNow;

        // Prefer authoritative Google state when client is configured
        GooglePlaySubscriptionInfo? info = null;
        if (_playClient.IsConfigured)
        {
            try
            {
                info = await _playClient.GetSubscriptionAsync(
                    _settings.PackageName, purchaseToken, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RTDN: failed to fetch subscription from Google for token.");
            }
        }

        switch (notifType)
        {
            case 1: // RECOVERED
            case 2: // RENEWED
            case 4: // PURCHASED
            case 7: // RESTARTED
                if (userSub is not null)
                {
                    var expiry = info?.ExpiryTime ?? userSub.ExpiredAt ?? now.AddDays(_settings.MonthlyDurationDays);
                    if (info?.ExpiryTime is { } googleExp)
                        expiry = googleExp;
                    else if (notifType == 2)
                        expiry = (userSub.ExpiredAt is { } e && e > now ? e : now)
                            .AddDays(_settings.MonthlyDurationDays);

                    userSub.Status = SubscriptionStatus.Active;
                    userSub.ExpiredAt = expiry;
                    userSub.LastBillingAt = now;
                    userSub.NextBillingAt = expiry;
                    userSub.UpdatedAt = now;
                    await SyncTierToIamAsync(userSub.UserId, "Premium", cancellationToken);
                }
                else if (!string.IsNullOrEmpty(productId) && info is { IsEntitlementActive: true })
                {
                    // Purchase arrived via RTDN before client verify — cannot map user; log for ops.
                    _logger.LogWarning(
                        "RTDN purchase/renew for unknown token. ProductId={ProductId} Type={Type}",
                        productId, notifType);
                }
                break;

            case 3: // CANCELED — keep entitlement until expiry
                if (userSub is not null)
                {
                    userSub.AutoRenew = false;
                    userSub.CancellationReason = "GooglePlayCanceled";
                    if (info?.ExpiryTime is { } exp)
                        userSub.ExpiredAt = exp;
                    userSub.UpdatedAt = now;
                }
                break;

            case 5: // ON_HOLD
            case 10: // PAUSED
                if (userSub is not null)
                {
                    userSub.Status = SubscriptionStatus.Paused;
                    userSub.UpdatedAt = now;
                    await SyncTierToIamAsync(userSub.UserId, "Free", cancellationToken);
                }
                break;

            case 6: // IN_GRACE_PERIOD
                if (userSub is not null)
                {
                    userSub.Status = SubscriptionStatus.PastDue;
                    userSub.UpdatedAt = now;
                }
                break;

            case 12: // REVOKED
            case 13: // EXPIRED
                if (userSub is not null)
                {
                    userSub.Status = notifType == 12
                        ? SubscriptionStatus.Cancelled
                        : SubscriptionStatus.Expired;
                    userSub.ExpiredAt = now;
                    userSub.UpdatedAt = now;
                    await SyncTierToIamAsync(userSub.UserId, "Free", cancellationToken);
                }
                break;

            default:
                _logger.LogInformation("RTDN notificationType={Type} ignored.", notifType);
                break;
        }

        // Attempt acknowledge on purchase-like events
        if (notifType is 4 or 2 or 1 or 7
            && !string.IsNullOrEmpty(productId)
            && _playClient.IsConfigured)
        {
            try
            {
                await _playClient.AcknowledgeSubscriptionAsync(
                    _settings.PackageName, productId, purchaseToken, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RTDN acknowledge failed for ProductId={ProductId}", productId);
            }
        }

        webhookEvent.Processed = true;
        webhookEvent.ProcessedAt = now;
        await _db.SaveChangesAsync(cancellationToken);

        return new GooglePlayRtdnProcessResult
        {
            Outcome = "Processed",
            Message = $"Handled notificationType={notifType}.",
            PurchaseToken = purchaseToken,
            NotificationType = notifType,
        };
    }

    private async Task<SubscriptionPlan> ResolvePlanAsync(
        Guid? planId,
        string productId,
        CancellationToken cancellationToken)
    {
        if (planId is { } id && id != Guid.Empty)
        {
            var byId = await _db.SubscriptionPlans
                .FirstOrDefaultAsync(p => p.Id == id && p.IsActive, cancellationToken);
            if (byId is not null)
            {
                if (!string.IsNullOrWhiteSpace(byId.GooglePlayProductId)
                    && !string.Equals(byId.GooglePlayProductId, productId, StringComparison.Ordinal))
                {
                    throw new BadRequestException(
                        $"ProductId '{productId}' does not match plan GooglePlayProductId '{byId.GooglePlayProductId}'.");
                }
                return byId;
            }
        }

        return await _db.SubscriptionPlans
                   .FirstOrDefaultAsync(
                       p => p.IsActive && p.GooglePlayProductId == productId,
                       cancellationToken)
                   ?? throw new NotFoundException(
                       nameof(SubscriptionPlan), productId);
    }

    private async Task<UserSubscription> ActivateOrExtendAsync(
        Guid userId,
        Guid planId,
        string purchaseToken,
        DateTimeOffset expiredAt,
        DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        var existing = await _db.UserSubscriptions
            .Where(s => s.UserId == userId && s.SubscriptionPlanId == planId)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing is null)
        {
            var created = new UserSubscription
            {
                UserId = userId,
                SubscriptionPlanId = planId,
                Status = SubscriptionStatus.Active,
                StartedAt = now,
                ExpiredAt = expiredAt,
                AutoRenew = true,
                LastBillingAt = now,
                NextBillingAt = expiredAt,
                ManagedBy = PaymentProvider.GooglePlay,
                ExternalSubscriptionId = purchaseToken,
            };
            _db.UserSubscriptions.Add(created);
            return created;
        }

        existing.Status = SubscriptionStatus.Active;
        existing.ExpiredAt = expiredAt;
        existing.LastBillingAt = now;
        existing.NextBillingAt = expiredAt;
        existing.ManagedBy = PaymentProvider.GooglePlay;
        existing.ExternalSubscriptionId = purchaseToken;
        existing.AutoRenew = true;
        existing.UpdatedAt = now;
        existing.CancellationReason = null;
        return existing;
    }

    private async Task SyncTierToIamAsync(Guid userId, string tier, CancellationToken cancellationToken)
    {
        try
        {
            await _iamClient.SetTierAsync(userId, tier, cancellationToken);
            _logger.LogInformation("Synced tier={Tier} to IAM for UserId={UserId} (GooglePlay).", tier, userId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex,
                "Failed to sync tier={Tier} to IAM for UserId={UserId} (GooglePlay).",
                tier, userId);
        }
    }

    // ── Pub/Sub / RTDN DTOs ──────────────────────────────────────────────────

    private sealed class PubSubPushEnvelope
    {
        public PubSubMessage? Message { get; set; }
        public string? Subscription { get; set; }
    }

    private sealed class PubSubMessage
    {
        public string? Data { get; set; }
        public string? MessageId { get; set; }
        public string? PublishTime { get; set; }
    }

    private sealed class DeveloperNotification
    {
        [JsonPropertyName("version")]
        public string? Version { get; set; }

        [JsonPropertyName("packageName")]
        public string? PackageName { get; set; }

        [JsonPropertyName("subscriptionNotification")]
        public SubscriptionNotificationPayload? SubscriptionNotification { get; set; }
    }

    private sealed class SubscriptionNotificationPayload
    {
        [JsonPropertyName("version")]
        public string? Version { get; set; }

        [JsonPropertyName("notificationType")]
        public int NotificationType { get; set; }

        [JsonPropertyName("purchaseToken")]
        public string? PurchaseToken { get; set; }

        [JsonPropertyName("subscriptionId")]
        public string? SubscriptionId { get; set; }
    }
}
