using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Net.payOS;
using Payment.Application.Clients;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Options;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;
using PayosItemData = Net.payOS.Types.ItemData;
using PayosPaymentData = Net.payOS.Types.PaymentData;
using PayosWebhookData = Net.payOS.Types.WebhookData;
using PayosWebhookType = Net.payOS.Types.WebhookType;

namespace Payment.Infrastructure.Services;

public class PayosPaymentService : IPayosPaymentService
{
    private const string ProviderName = "PayOS";
    private const string PayOsSuccessCode = "00";
    private const int PayOsDescriptionMaxLength = 25;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly PaymentDbContext _db;
    private readonly PayOS _payOS;
    private readonly PayosSettings _settings;
    private readonly IIamSubscriptionClient _iamClient;
    private readonly ILogger<PayosPaymentService> _logger;

    public PayosPaymentService(
        PaymentDbContext db,
        PayOS payOS,
        IOptions<PayosSettings> settings,
        IIamSubscriptionClient iamClient,
        ILogger<PayosPaymentService> logger)
    {
        _db        = db;
        _payOS     = payOS;
        _settings  = settings.Value;
        _iamClient = iamClient;
        _logger    = logger;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. POST /api/v1/payments/payos/create-link
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<CreatePaymentLinkResponse> CreatePaymentLinkAsync(
        Guid userId,
        CreatePaymentLinkRequest request,
        CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            throw new UnauthorizedException("User is not authenticated.");
        if (request.PlanId == Guid.Empty)
            throw new BadRequestException("PlanId is required.");

        var plan = await _db.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == request.PlanId, cancellationToken)
            ?? throw new NotFoundException(nameof(SubscriptionPlan), request.PlanId);

        if (!plan.IsActive)
            throw new BadRequestException("Subscription plan is not currently active.");

        var (baseAmount, durationDays) = request.BillingCycle switch
        {
            BillingCycle.Monthly => (plan.MonthlyPrice, _settings.MonthlyDurationDays),
            BillingCycle.Yearly  => (plan.YearlyPrice,  _settings.YearlyDurationDays),
            _ => throw new BadRequestException("Invalid billing cycle.")
        };

        if (baseAmount <= 0)
            throw new BadRequestException("Selected billing cycle has no valid price configured.");

        // ── Validate & apply coupon ─────────────────────────────────────────
        var (finalAmount, appliedCouponCode) = await ApplyCouponAsync(
            baseAmount, request.CouponCode, cancellationToken);

        // ── Generate unique numeric OrderCode (PayOS requires `long`) ───────
        // Unix-ms * 1000 + 0..999 random → microsecond-like uniqueness,
        // well within long range and unique enough for hundreds of req/sec/user.
        var orderCode = (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000)
                        + Random.Shared.Next(0, 1000);

        // ── Persist Transaction in Pending state BEFORE calling PayOS ────────
        var transaction = new Transaction
        {
            UserId                    = userId,
            TransactionType           = TransactionType.Subscription,
            Status                    = TransactionStatus.Pending,
            PaymentMethod             = PaymentMethod.Momo,
            Provider                  = PaymentProvider.PayOS,
            Amount                    = finalAmount,
            Currency                  = plan.Currency,
            OrderCode                 = orderCode,
            RelatedEntityType         = nameof(SubscriptionPlan),
            RelatedEntityId           = plan.Id,
            Description               = $"SYNC {plan.Name} ({request.BillingCycle}, {durationDays}d)",
            SpendingAuthorizationType = SpendingAuthorizationType.ManualApproval,
            IsAiInitiated             = false,
            CouponCode                = appliedCouponCode
        };

        // Dùng finalAmount thay vì amount trong phần còn lại
        var amount = finalAmount;
        _db.Transactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);

        // ── Call PayOS to obtain checkoutUrl + QR code ──────────────────────
        // PayOS description is capped at 25 chars — use a short code instead of the plan name.
        var description = $"SYNC-{orderCode}";
        if (description.Length > PayOsDescriptionMaxLength)
            description = description[..PayOsDescriptionMaxLength];

        var amountInt = (int)Math.Round(amount, 0, MidpointRounding.AwayFromZero);
        var items = new List<PayosItemData>
        {
            new PayosItemData(plan.Name, 1, amountInt)
        };

        var paymentData = new PayosPaymentData(
            orderCode:   orderCode,
            amount:      amountInt,
            description: description,
            items:       items,
            cancelUrl:   _settings.CancelUrl,
            returnUrl:   _settings.ReturnUrl);

        try
        {
            var result = await _payOS.createPaymentLink(paymentData);

            return new CreatePaymentLinkResponse
            {
                OrderCode     = result.orderCode,
                TransactionId = transaction.Id,
                Amount        = result.amount,
                Currency      = plan.Currency,
                CheckoutUrl   = result.checkoutUrl,
                QrCode        = result.qrCode,
                PaymentLinkId = result.paymentLinkId,
                AccountNumber = result.accountNumber,
                Bin           = result.bin,
                Status        = result.status,
                ExpiredAt     = result.expiredAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "PayOS createPaymentLink failed for OrderCode={OrderCode}, UserId={UserId}",
                orderCode, userId);

            transaction.Status       = TransactionStatus.Failed;
            transaction.FailedReason = $"PayOS error: {ex.Message}";
            transaction.UpdatedAt    = DateTimeOffset.UtcNow;
            try
            {
                await _db.SaveChangesAsync(cancellationToken);
            }
            catch (Exception saveEx)
            {
                _logger.LogError(saveEx, "Failed to mark transaction as Failed after PayOS error.");
            }

            throw new PaymentGatewayException("Failed to create payment link with PayOS. Please try again later.", ex);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. POST /api/v1/payments/payos/webhook
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<PayosWebhookProcessResult> ProcessWebhookAsync(
        string rawJsonBody,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(rawJsonBody))
            throw new BadRequestException("Webhook payload is empty.");

        // ── 1. Deserialize PayOS webhook envelope ────────────────────────────
        PayosWebhookType webhookEnvelope;
        try
        {
            webhookEnvelope = JsonSerializer.Deserialize<PayosWebhookType>(rawJsonBody, JsonOptions)
                ?? throw new BadRequestException("Webhook payload is not valid JSON.");
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "PayOS webhook: invalid JSON body");
            throw new BadRequestException("Webhook payload is not valid JSON.");
        }

        // ── 2. Verify signature using PayOS SDK (throws on tampering) ────────
        PayosWebhookData webhookData;
        try
        {
            webhookData = _payOS.verifyPaymentWebhookData(webhookEnvelope);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "PayOS webhook signature verification failed");
            throw new UnauthorizedException("Invalid webhook signature.");
        }

        var externalEventId = webhookData.orderCode.ToString();

        // ── 3. Idempotency: short-circuit if already processed ──────────────
        var existingEvent = await _db.PaymentWebhookEvents
            .FirstOrDefaultAsync(
                e => e.Provider == ProviderName && e.ExternalEventId == externalEventId,
                cancellationToken);

        if (existingEvent is { Processed: true })
        {
            _logger.LogInformation(
                "PayOS webhook for OrderCode={OrderCode} already processed — returning OK.",
                externalEventId);
            return new PayosWebhookProcessResult
            {
                Outcome   = WebhookProcessOutcome.AlreadyProcessed,
                OrderCode = webhookData.orderCode,
                Message   = "Webhook already processed (idempotent)."
            };
        }

        // ── 4. Atomic write: webhook event + transaction + user subscription
        await using var dbTx = await _db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var isSuccess = string.Equals(webhookData.code, PayOsSuccessCode, StringComparison.Ordinal);
            var now = DateTimeOffset.UtcNow;

            // a) Upsert PaymentWebhookEvent
            if (existingEvent is null)
            {
                existingEvent = new PaymentWebhookEvent
                {
                    Provider        = ProviderName,
                    EventType       = isSuccess ? "payment.success" : "payment.failed",
                    ExternalEventId = externalEventId,
                    PayloadJson     = rawJsonBody,
                    Processed       = false,
                    RetryCount      = 0
                };
                _db.PaymentWebhookEvents.Add(existingEvent);
            }
            else
            {
                existingEvent.PayloadJson = rawJsonBody;
                existingEvent.RetryCount += 1;
                existingEvent.UpdatedAt   = now;
            }
            await _db.SaveChangesAsync(cancellationToken);

            // b) Find Transaction by OrderCode
            var transaction = await _db.Transactions
                .FirstOrDefaultAsync(
                    t => t.OrderCode == webhookData.orderCode && t.Provider == PaymentProvider.PayOS,
                    cancellationToken);

            if (transaction is null)
            {
                existingEvent.ErrorMessage = "Transaction not found for OrderCode.";
                existingEvent.Processed    = true;
                existingEvent.ProcessedAt  = now;
                await _db.SaveChangesAsync(cancellationToken);
                await dbTx.CommitAsync(cancellationToken);

                _logger.LogWarning("PayOS webhook: no Transaction for OrderCode={OrderCode}", externalEventId);
                return new PayosWebhookProcessResult
                {
                    Outcome   = WebhookProcessOutcome.TransactionNotFound,
                    OrderCode = webhookData.orderCode,
                    Message   = "Transaction not found."
                };
            }

            // c) If already in a final state, just mark event processed and return
            if (transaction.Status is TransactionStatus.Succeeded
                or TransactionStatus.Failed
                or TransactionStatus.Refunded
                or TransactionStatus.Cancelled)
            {
                existingEvent.Processed   = true;
                existingEvent.ProcessedAt = now;
                await _db.SaveChangesAsync(cancellationToken);
                await dbTx.CommitAsync(cancellationToken);

                return new PayosWebhookProcessResult
                {
                    Outcome   = WebhookProcessOutcome.TransactionAlreadyFinal,
                    OrderCode = webhookData.orderCode,
                    Message   = $"Transaction already in final state ({transaction.Status})."
                };
            }

            // d) Apply payment result to Transaction
            transaction.ExternalReferenceId = webhookData.reference;
            transaction.RawProviderPayload  = rawJsonBody;
            transaction.ProcessedAt         = now;
            transaction.UpdatedAt           = now;

            if (!isSuccess)
            {
                transaction.Status       = TransactionStatus.Failed;
                transaction.FailedReason = webhookData.desc;

                existingEvent.Processed   = true;
                existingEvent.ProcessedAt = now;
                await _db.SaveChangesAsync(cancellationToken);
                await dbTx.CommitAsync(cancellationToken);

                return new PayosWebhookProcessResult
                {
                    Outcome   = WebhookProcessOutcome.PaymentFailed,
                    OrderCode = webhookData.orderCode,
                    Message   = $"Payment failed: {webhookData.desc}"
                };
            }

            transaction.Status = TransactionStatus.Succeeded;

            // e) Activate / extend UserSubscription if this Transaction is for a SubscriptionPlan
            if (transaction.RelatedEntityType == nameof(SubscriptionPlan)
                && transaction.RelatedEntityId is { } planId)
            {
                await ActivateSubscriptionAsync(
                    transaction.UserId,
                    planId,
                    transaction.Amount,
                    webhookData.paymentLinkId,
                    now,
                    cancellationToken);

                // Sync tier to IAM — fire-and-forget style: nuốt lỗi để không làm fail webhook
                await SyncTierToIamAsync(transaction.UserId, "Premium", cancellationToken);
                await IncrementCouponUsageAsync(transaction.CouponCode, cancellationToken);
            }

            // f) Mark webhook event as processed
            existingEvent.Processed   = true;
            existingEvent.ProcessedAt = now;

            await _db.SaveChangesAsync(cancellationToken);
            await dbTx.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "PayOS webhook processed successfully. OrderCode={OrderCode}, UserId={UserId}",
                webhookData.orderCode, transaction.UserId);

            return new PayosWebhookProcessResult
            {
                Outcome   = WebhookProcessOutcome.Processed,
                OrderCode = webhookData.orderCode,
                Message   = "Payment confirmed and subscription activated."
            };
        }
        catch (AppException)
        {
            await dbTx.RollbackAsync(cancellationToken);
            throw;
        }
        catch (Exception ex)
        {
            await dbTx.RollbackAsync(cancellationToken);
            _logger.LogError(ex, "Unexpected error while processing PayOS webhook for OrderCode={OrderCode}", externalEventId);
            throw new AppExceptionWrapper("An unexpected error occurred while processing the webhook.", ex);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. DEV-ONLY: POST /api/v1/payments/dev/confirm/{orderCode}
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<PayosWebhookProcessResult> ActivateForDevAsync(
        long orderCode,
        CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;

        var transaction = await _db.Transactions
            .FirstOrDefaultAsync(
                t => t.OrderCode == orderCode && t.Provider == PaymentProvider.PayOS,
                cancellationToken);

        if (transaction is null)
            return new PayosWebhookProcessResult
            {
                Outcome   = WebhookProcessOutcome.TransactionNotFound,
                OrderCode = orderCode,
                Message   = "Transaction not found for this orderCode."
            };

        if (transaction.Status is TransactionStatus.Succeeded
            or TransactionStatus.Failed
            or TransactionStatus.Refunded
            or TransactionStatus.Cancelled)
            return new PayosWebhookProcessResult
            {
                Outcome   = WebhookProcessOutcome.TransactionAlreadyFinal,
                OrderCode = orderCode,
                Message   = $"Transaction already in final state ({transaction.Status})."
            };

        transaction.Status      = TransactionStatus.Succeeded;
        transaction.ProcessedAt = now;
        transaction.UpdatedAt   = now;

        if (transaction.RelatedEntityType == nameof(SubscriptionPlan)
            && transaction.RelatedEntityId is { } planId)
        {
            await ActivateSubscriptionAsync(
                transaction.UserId,
                planId,
                transaction.Amount,
                "dev-confirm",
                now,
                cancellationToken);

            await SyncTierToIamAsync(transaction.UserId, "Premium", cancellationToken);
            await IncrementCouponUsageAsync(transaction.CouponCode, cancellationToken);
        }

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "[DEV] Simulated payment confirmed. OrderCode={OrderCode}, UserId={UserId}",
            orderCode, transaction.UserId);

        return new PayosWebhookProcessResult
        {
            Outcome   = WebhookProcessOutcome.Processed,
            OrderCode = orderCode,
            Message   = "[DEV] Payment simulated and subscription activated."
        };
    }

    // ── Internal helpers ────────────────────────────────────────────────────

    private async Task ActivateSubscriptionAsync(
        Guid userId,
        Guid planId,
        decimal paidAmount,
        string? externalSubscriptionId,
        DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        var plan = await _db.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Id == planId, cancellationToken);
        if (plan is null)
        {
            _logger.LogWarning("PayOS webhook: SubscriptionPlan {PlanId} not found while activating subscription.", planId);
            return;
        }

        // Pick duration based on the amount paid: any payment >= YearlyPrice → yearly, otherwise monthly.
        var durationDays = (plan.YearlyPrice > 0 && paidAmount >= plan.YearlyPrice)
            ? _settings.YearlyDurationDays
            : _settings.MonthlyDurationDays;

        var existing = await _db.UserSubscriptions
            .Where(s => s.UserId == userId && s.SubscriptionPlanId == planId)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing is null)
        {
            var newSub = new UserSubscription
            {
                UserId                 = userId,
                SubscriptionPlanId     = planId,
                Status                 = SubscriptionStatus.Active,
                StartedAt              = now,
                ExpiredAt              = now.AddDays(durationDays),
                AutoRenew              = false,
                LastBillingAt          = now,
                NextBillingAt          = now.AddDays(durationDays),
                ManagedBy              = PaymentProvider.PayOS,
                ExternalSubscriptionId = externalSubscriptionId
            };
            _db.UserSubscriptions.Add(newSub);
            return;
        }

        // Extend from current expiry if still active; else restart from now.
        var baseDate = (existing.ExpiredAt is { } exp && exp > now) ? exp : now;
        existing.Status                 = SubscriptionStatus.Active;
        existing.ExpiredAt              = baseDate.AddDays(durationDays);
        existing.LastBillingAt          = now;
        existing.NextBillingAt          = existing.ExpiredAt;
        existing.ManagedBy              = PaymentProvider.PayOS;
        existing.ExternalSubscriptionId = externalSubscriptionId;
        existing.UpdatedAt              = now;
    }

    private async Task<(decimal finalAmount, string? couponCode)> ApplyCouponAsync(
        decimal baseAmount,
        string? rawCode,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(rawCode))
            return (baseAmount, null);

        var code = rawCode.Trim().ToUpper();
        var now  = DateTimeOffset.UtcNow;

        if (code.StartsWith("SYNC-10-"))
        {
            var discount = Math.Round(baseAmount * 10m / 100m, 0, MidpointRounding.AwayFromZero);
            var finalAmount = Math.Max(0, baseAmount - discount);
            return (finalAmount, code);
        }
        if (code.StartsWith("SYNC-20-"))
        {
            var discount = Math.Round(baseAmount * 20m / 100m, 0, MidpointRounding.AwayFromZero);
            var finalAmount = Math.Max(0, baseAmount - discount);
            return (finalAmount, code);
        }

        var campaign = await _db.PromotionCampaigns
            .FirstOrDefaultAsync(p =>
                p.CouponCode == code &&
                p.IsActive &&
                p.StartsAt <= now &&
                p.EndsAt   >= now,
                cancellationToken);

        if (campaign is null)
            throw new BadRequestException($"Coupon code '{code}' is invalid or has expired.");

        if (campaign.UsageLimit > 0 && campaign.UsageCount >= campaign.UsageLimit)
            throw new BadRequestException($"Coupon code '{code}' has reached its usage limit.");

        if (baseAmount < campaign.MinimumSpend)
            throw new BadRequestException(
                $"Order total must be at least {campaign.MinimumSpend} to use this coupon.");

        var discountAmt = campaign.PromotionType switch
        {
            PromotionType.PercentageDiscount => Math.Round(baseAmount * campaign.Value / 100, 0, MidpointRounding.AwayFromZero),
            PromotionType.FixedDiscount      => campaign.Value,
            _                                => 0m
        };

        var finalAmt = Math.Max(0, baseAmount - discountAmt);
        return (finalAmt, code);
    }

    private async Task IncrementCouponUsageAsync(string? couponCode, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(couponCode)) return;

        var code = couponCode.Trim().ToUpper();
        if (code.StartsWith("SYNC-10-") || code.StartsWith("SYNC-20-"))
            return;

        var campaign = await _db.PromotionCampaigns
            .FirstOrDefaultAsync(p => p.CouponCode == couponCode, cancellationToken);

        if (campaign is null) return;

        campaign.UsageCount += 1;
        campaign.UpdatedAt   = DateTimeOffset.UtcNow;
    }

    private async Task SyncTierToIamAsync(Guid userId, string tier, CancellationToken cancellationToken)
    {
        try
        {
            await _iamClient.SetTierAsync(userId, tier, cancellationToken);
            _logger.LogInformation("Synced tier={Tier} to IAM for UserId={UserId}.", tier, userId);
        }
        catch (Exception ex)
        {
            // Nuốt lỗi để không làm fail webhook/dev-confirm — IAM có thể tạm unavailable.
            // Tier sẽ được đối chiếu lại khi có job reconcile sau này.
            _logger.LogWarning(ex,
                "Failed to sync tier={Tier} to IAM for UserId={UserId}. Will require manual reconciliation.",
                tier, userId);
        }
    }

    /// <summary>Concrete subclass so we can wrap unexpected exceptions and route them through GlobalExceptionHandler.</summary>
    private sealed class AppExceptionWrapper : AppException
    {
        public AppExceptionWrapper(string message, Exception inner) : base(message, inner) { }
    }
}
