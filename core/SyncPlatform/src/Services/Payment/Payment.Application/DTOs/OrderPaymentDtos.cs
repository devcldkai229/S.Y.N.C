using Payment.Application.Helpers;
using Payment.Domain.Enums;

namespace Payment.Application.DTOs;

public class WalletBalanceDto
{
    /// <summary>Spendable SYNC coins (1 coin = 100 VND).</summary>
    public decimal CoinBalance { get; set; }

    /// <summary>Alias of <see cref="CoinBalance"/> for older clients.</summary>
    public decimal AvailableBalance { get; set; }

    public decimal VndPerCoin { get; set; } = WalletCoinHelper.VndPerCoin;

    public string Currency { get; set; } = "COIN";
}

public class ChargeOrderWalletRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";

    public bool IsAiInitiated { get; set; }
}

public class ChargeOrderWalletResponseDto
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public string? FailureReason { get; set; }

    public bool InsufficientBalance { get; set; }
}

public class CreateCodTransactionRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class CreateCodTransactionResponseDto
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }
}

public class CreateMomoPaymentRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";

    public string? OrderInfo { get; set; }
}

public class CreateMomoPaymentResponseDto
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public string? PayUrl { get; set; }

    public string? Deeplink { get; set; }

    public string? FailureReason { get; set; }
}

public class CreateVietQrPaymentRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class CreateVietQrPaymentResponseDto
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public long? PayOsOrderCode { get; set; }

    public string? CheckoutUrl { get; set; }

    public string? QrCode { get; set; }

    public string? FailureReason { get; set; }
}

public class MomoIpnPayloadDto
{
    public string PartnerCode { get; set; } = string.Empty;

    public string OrderId { get; set; } = string.Empty;

    public string RequestId { get; set; } = string.Empty;

    public long Amount { get; set; }

    public string OrderInfo { get; set; } = string.Empty;

    public string OrderType { get; set; } = string.Empty;

    public long TransId { get; set; }

    public int ResultCode { get; set; }

    public string Message { get; set; } = string.Empty;

    public string PayType { get; set; } = string.Empty;

    public long ResponseTime { get; set; }

    public string ExtraData { get; set; } = string.Empty;

    public string Signature { get; set; } = string.Empty;
}

public class MomoIpnResultDto
{
    public bool Accepted { get; set; }

    public bool Paid { get; set; }

    public Guid? OrderId { get; set; }

    public Guid? TransactionId { get; set; }

    public Guid? UserId { get; set; }
}
