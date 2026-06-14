using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Net.payOS;
using Payment.Application.Clients;
using Payment.Application.DTOs;
using Payment.Application.Helpers;
using Payment.Application.Options;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;
using PayosItemData = Net.payOS.Types.ItemData;
using PayosPaymentData = Net.payOS.Types.PaymentData;

namespace Payment.Infrastructure.Services;

public class OrderPaymentService : IOrderPaymentService
{
    private const string ProviderName = "Momo";
    private const int PayOsDescriptionMaxLength = 25;

    private readonly PaymentDbContext _db;
    private readonly IInternalWalletService _walletService;
    private readonly MomoSettings _momoSettings;
    private readonly PayOS _payOS;
    private readonly PayosSettings _payosSettings;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IOrderPaymentNotifyClient _orderNotifyClient;
    private readonly ILogger<OrderPaymentService> _logger;

    public OrderPaymentService(
        PaymentDbContext db,
        IInternalWalletService walletService,
        IOptions<MomoSettings> momoSettings,
        PayOS payOS,
        IOptions<PayosSettings> payosSettings,
        IHttpClientFactory httpClientFactory,
        IOrderPaymentNotifyClient orderNotifyClient,
        ILogger<OrderPaymentService> logger)
    {
        _db = db;
        _walletService = walletService;
        _momoSettings = momoSettings.Value;
        _payOS = payOS;
        _payosSettings = payosSettings.Value;
        _httpClientFactory = httpClientFactory;
        _orderNotifyClient = orderNotifyClient;
        _logger = logger;
    }

    public async Task<WalletBalanceDto> GetWalletBalanceAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var wallet = await _db.Wallets.AsNoTracking().FirstOrDefaultAsync(w => w.UserId == userId, cancellationToken);
        var coins = wallet?.RewardCoinBalance ?? 0m;
        return new WalletBalanceDto
        {
            CoinBalance = coins,
            AvailableBalance = coins,
            VndPerCoin = WalletCoinHelper.VndPerCoin,
            Currency = "COIN",
        };
    }

    public async Task<ChargeOrderWalletResponseDto> ChargeOrderWalletAsync(
        ChargeOrderWalletRequestDto request,
        CancellationToken cancellationToken = default)
    {
        var result = await _walletService.ChargeMealOrderAsync(new ChargeMealOrderRequestDto
        {
            UserId = request.UserId,
            OrderId = request.OrderId,
            Amount = request.Amount,
            Currency = request.Currency,
            IsAiInitiated = request.IsAiInitiated,
        }, cancellationToken);

        return new ChargeOrderWalletResponseDto
        {
            Success = result.Success,
            TransactionId = result.TransactionId,
            FailureReason = result.FailureReason,
            InsufficientBalance = result.FailureReason?.Contains("Insufficient", StringComparison.OrdinalIgnoreCase) == true,
        };
    }

    public async Task<CreateCodTransactionResponseDto> CreateCodTransactionAsync(
        CreateCodTransactionRequestDto request,
        CancellationToken cancellationToken = default)
    {
        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == request.UserId, cancellationToken);
        var transaction = new Transaction
        {
            WalletId = wallet?.Id,
            UserId = request.UserId,
            TransactionType = TransactionType.MealPurchase,
            Status = TransactionStatus.Pending,
            PaymentMethod = PaymentMethod.COD,
            Amount = request.Amount,
            Currency = request.Currency,
            RelatedEntityType = "Order",
            RelatedEntityId = request.OrderId,
            Description = $"COD order {request.OrderId}",
            Provider = PaymentProvider.InternalWallet,
            OrderCode = Random.Shared.NextInt64(100000000, 999999999),
        };

        _db.Transactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);

        return new CreateCodTransactionResponseDto { Success = true, TransactionId = transaction.Id };
    }

    public async Task<CreateVietQrPaymentResponseDto> CreateVietQrPaymentAsync(
        CreateVietQrPaymentRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return new CreateVietQrPaymentResponseDto
            {
                Success = false,
                FailureReason = "Amount must be greater than zero.",
            };
        }

        var orderCode = (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000) + Random.Shared.Next(0, 1000);
        var amountInt = (int)Math.Round(request.Amount, 0, MidpointRounding.AwayFromZero);

        var transaction = new Transaction
        {
            UserId = request.UserId,
            TransactionType = TransactionType.MealPurchase,
            Status = TransactionStatus.Pending,
            PaymentMethod = PaymentMethod.VietQR,
            Provider = PaymentProvider.PayOS,
            Amount = request.Amount,
            Currency = request.Currency,
            RelatedEntityType = "Order",
            RelatedEntityId = request.OrderId,
            Description = $"Order {request.OrderCode}",
            OrderCode = orderCode,
        };
        _db.Transactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(_payosSettings.ClientId))
        {
            return new CreateVietQrPaymentResponseDto
            {
                Success = true,
                TransactionId = transaction.Id,
                PayOsOrderCode = orderCode,
                CheckoutUrl = $"https://pay.payos.vn/web/{orderCode}",
                QrCode = $"00020101021238570010A00000072701270006{orderCode}",
            };
        }

        var description = $"ORD-{request.OrderCode}";
        if (description.Length > PayOsDescriptionMaxLength)
            description = description[..PayOsDescriptionMaxLength];

        var items = new List<PayosItemData>
        {
            new PayosItemData($"Don {request.OrderCode}", 1, amountInt),
        };

        var paymentData = new PayosPaymentData(
            orderCode: orderCode,
            amount: amountInt,
            description: description,
            items: items,
            cancelUrl: _payosSettings.CancelUrl,
            returnUrl: _payosSettings.ReturnUrl);

        try
        {
            var result = await _payOS.createPaymentLink(paymentData);
            return new CreateVietQrPaymentResponseDto
            {
                Success = true,
                TransactionId = transaction.Id,
                PayOsOrderCode = result.orderCode,
                CheckoutUrl = result.checkoutUrl,
                QrCode = result.qrCode,
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PayOS VietQR create failed for order {OrderId}", request.OrderId);
            transaction.Status = TransactionStatus.Failed;
            transaction.FailedReason = ex.Message;
            transaction.UpdatedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);

            return new CreateVietQrPaymentResponseDto
            {
                Success = false,
                FailureReason = "Không tạo được thanh toán VietQR.",
            };
        }
    }

    public async Task<CreateMomoPaymentResponseDto> CreateMomoPaymentAsync(
        CreateMomoPaymentRequestDto request,
        CancellationToken cancellationToken = default)
    {
        var requestId = Guid.NewGuid().ToString();
        var momoOrderId = $"{request.OrderId:N}";
        var amount = (long)Math.Round(request.Amount, 0, MidpointRounding.AwayFromZero);
        var orderInfo = string.IsNullOrWhiteSpace(request.OrderInfo)
            ? $"Thanh toan don {request.OrderCode}"
            : request.OrderInfo!;
        var extraData = string.Empty;
        var requestType = "captureWallet";

        var transaction = new Transaction
        {
            UserId = request.UserId,
            TransactionType = TransactionType.MealPurchase,
            Status = TransactionStatus.Pending,
            PaymentMethod = PaymentMethod.Momo,
            Provider = PaymentProvider.Momo,
            Amount = request.Amount,
            Currency = request.Currency,
            RelatedEntityType = "Order",
            RelatedEntityId = request.OrderId,
            Description = orderInfo,
            OrderCode = Random.Shared.NextInt64(100000000, 999999999),
            ExternalReferenceId = requestId,
        };
        _db.Transactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);

        if (!_momoSettings.Enabled)
        {
            return new CreateMomoPaymentResponseDto
            {
                Success = true,
                TransactionId = transaction.Id,
                PayUrl = $"https://test-payment.momo.vn/mock-pay?orderId={momoOrderId}",
                Deeplink = $"momo://app?action=pay&orderId={momoOrderId}",
            };
        }

        var signature = BuildMomoCreateSignature(
            _momoSettings.AccessKey,
            amount.ToString(),
            extraData,
            _momoSettings.IpnUrl,
            momoOrderId,
            orderInfo,
            _momoSettings.PartnerCode,
            _momoSettings.RedirectUrl,
            requestId,
            requestType);

        var body = new
        {
            partnerCode = _momoSettings.PartnerCode,
            partnerName = "SYNC",
            storeId = "SYNC",
            requestId,
            amount,
            orderId = momoOrderId,
            orderInfo,
            redirectUrl = _momoSettings.RedirectUrl,
            ipnUrl = _momoSettings.IpnUrl,
            lang = "vi",
            requestType,
            autoCapture = true,
            extraData,
            signature,
        };

        var client = _httpClientFactory.CreateClient("Momo");
        var response = await client.PostAsJsonAsync(_momoSettings.Endpoint, body, cancellationToken);
        var json = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("MoMo create payment failed: {Body}", json);
            return new CreateMomoPaymentResponseDto
            {
                Success = false,
                FailureReason = "Không tạo được thanh toán MoMo.",
            };
        }

        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        var resultCode = root.TryGetProperty("resultCode", out var rc) ? rc.GetInt32() : -1;
        if (resultCode != 0)
        {
            return new CreateMomoPaymentResponseDto
            {
                Success = false,
                FailureReason = root.TryGetProperty("message", out var msg) ? msg.GetString() : "MoMo error",
            };
        }

        return new CreateMomoPaymentResponseDto
        {
            Success = true,
            TransactionId = transaction.Id,
            PayUrl = root.TryGetProperty("payUrl", out var payUrl) ? payUrl.GetString() : null,
            Deeplink = root.TryGetProperty("deeplink", out var deeplink) ? deeplink.GetString() : null,
        };
    }

    public async Task<MomoIpnResultDto> ProcessMomoIpnAsync(
        MomoIpnPayloadDto payload,
        string rawJson,
        CancellationToken cancellationToken = default)
    {
        var eventKey = $"{payload.RequestId}:{payload.OrderId}";
        var existing = await _db.PaymentWebhookEvents
            .FirstOrDefaultAsync(e => e.Provider == ProviderName && e.ExternalEventId == eventKey, cancellationToken);

        if (existing?.Processed == true)
            return new MomoIpnResultDto { Accepted = true };

        existing ??= new PaymentWebhookEvent
        {
            Provider = ProviderName,
            ExternalEventId = eventKey,
            EventType = "IPN",
            PayloadJson = rawJson,
        };
        if (existing.Id == Guid.Empty)
            _db.PaymentWebhookEvents.Add(existing);

        if (!VerifyMomoIpnSignature(payload))
        {
            existing.ErrorMessage = "Invalid signature";
            await _db.SaveChangesAsync(cancellationToken);
            return new MomoIpnResultDto { Accepted = false };
        }

        if (!Guid.TryParse(payload.OrderId, out var orderId))
        {
            existing.ErrorMessage = "Invalid order id";
            await _db.SaveChangesAsync(cancellationToken);
            return new MomoIpnResultDto { Accepted = false };
        }

        var transaction = await _db.Transactions
            .Where(t => t.RelatedEntityId == orderId && t.PaymentMethod == PaymentMethod.Momo)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (transaction == null)
        {
            existing.ErrorMessage = "Transaction not found";
            await _db.SaveChangesAsync(cancellationToken);
            return new MomoIpnResultDto { Accepted = false };
        }

        var paid = payload.ResultCode == 0;
        transaction.Status = paid ? TransactionStatus.Succeeded : TransactionStatus.Failed;
        transaction.ProcessedAt = DateTimeOffset.UtcNow;
        transaction.UpdatedAt = DateTimeOffset.UtcNow;
        transaction.ExternalReferenceId = payload.TransId.ToString();

        existing.Processed = true;
        existing.ProcessedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        if (paid)
        {
            await _orderNotifyClient.ConfirmOrderPaymentAsync(orderId, transaction.Id, cancellationToken);
        }

        return new MomoIpnResultDto
        {
            Accepted = true,
            Paid = paid,
            OrderId = orderId,
            TransactionId = transaction.Id,
            UserId = transaction.UserId,
        };
    }

    private bool VerifyMomoIpnSignature(MomoIpnPayloadDto payload)
    {
        if (!_momoSettings.Enabled || string.IsNullOrEmpty(_momoSettings.SecretKey))
            return true;

        var raw = $"accessKey={_momoSettings.AccessKey}" +
                  $"&amount={payload.Amount}" +
                  $"&extraData={payload.ExtraData}" +
                  $"&message={payload.Message}" +
                  $"&orderId={payload.OrderId}" +
                  $"&orderInfo={payload.OrderInfo}" +
                  $"&orderType={payload.OrderType}" +
                  $"&partnerCode={payload.PartnerCode}" +
                  $"&payType={payload.PayType}" +
                  $"&requestId={payload.RequestId}" +
                  $"&responseTime={payload.ResponseTime}" +
                  $"&resultCode={payload.ResultCode}" +
                  $"&transId={payload.TransId}";

        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_momoSettings.SecretKey));
        var hash = Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(raw))).ToLowerInvariant();
        return string.Equals(hash, payload.Signature, StringComparison.OrdinalIgnoreCase);
    }

    private string BuildMomoCreateSignature(
        string accessKey,
        string amount,
        string extraData,
        string ipnUrl,
        string orderId,
        string orderInfo,
        string partnerCode,
        string redirectUrl,
        string requestId,
        string requestType)
    {
        var raw = $"accessKey={accessKey}" +
                  $"&amount={amount}" +
                  $"&extraData={extraData}" +
                  $"&ipnUrl={ipnUrl}" +
                  $"&orderId={orderId}" +
                  $"&orderInfo={orderInfo}" +
                  $"&partnerCode={partnerCode}" +
                  $"&redirectUrl={redirectUrl}" +
                  $"&requestId={requestId}" +
                  $"&requestType={requestType}";

        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_momoSettings.SecretKey));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(raw))).ToLowerInvariant();
    }
}
