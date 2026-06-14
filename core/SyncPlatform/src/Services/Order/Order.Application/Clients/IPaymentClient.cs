namespace Order.Application.Clients;

public class ChargeMealOrderRequest
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";

    public Guid? VoucherId { get; set; }

    public bool IsAiInitiated { get; set; }
}

public class ChargeMealOrderResult
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public decimal DiscountAmount { get; set; }

    public string? FailureReason { get; set; }

    public bool InsufficientBalance { get; set; }
}

public class RefundMealOrderRequest
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public Guid? OriginalTransactionId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class RefundMealOrderResult
{
    public bool Success { get; set; }

    public Guid? RefundTransactionId { get; set; }

    public string? FailureReason { get; set; }
}

public class ValidateVoucherRequest
{
    public Guid UserId { get; set; }

    public string Code { get; set; } = string.Empty;

    public decimal OrderAmount { get; set; }

    public Guid? PartnerId { get; set; }
}

public class ValidateVoucherResult
{
    public bool Valid { get; set; }

    public decimal DiscountAmount { get; set; }

    public Guid? VoucherId { get; set; }

    public Guid? CampaignId { get; set; }

    public string? Message { get; set; }
}

public class MarkVoucherUsedRequest
{
    public Guid UserId { get; set; }

    public string Code { get; set; } = string.Empty;

    public Guid OrderId { get; set; }
}

public class CreateVietQrPaymentRequest
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class CreateVietQrPaymentResult
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public long? PayOsOrderCode { get; set; }

    public string? CheckoutUrl { get; set; }

    public string? QrCode { get; set; }

    public string? FailureReason { get; set; }
}

public class CreateMomoPaymentRequest
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class CreateMomoPaymentResult
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public string? PayUrl { get; set; }

    public string? Deeplink { get; set; }

    public string? FailureReason { get; set; }
}

public class CreateCodPaymentRequest
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class CreateCodPaymentResult
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }
}

public interface IPaymentClient
{
    Task<ChargeMealOrderResult> ChargeMealOrderAsync(
        ChargeMealOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<RefundMealOrderResult> RefundMealOrderAsync(
        RefundMealOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<ValidateVoucherResult> ValidateVoucherAsync(
        ValidateVoucherRequest request,
        CancellationToken cancellationToken = default);

    Task MarkVoucherUsedAsync(
        MarkVoucherUsedRequest request,
        CancellationToken cancellationToken = default);

    Task<CreateCodPaymentResult> CreateCodTransactionAsync(
        CreateCodPaymentRequest request,
        CancellationToken cancellationToken = default);

    Task<CreateVietQrPaymentResult> CreateVietQrPaymentAsync(
        CreateVietQrPaymentRequest request,
        CancellationToken cancellationToken = default);

    Task<CreateMomoPaymentResult> CreateMomoPaymentAsync(
        CreateMomoPaymentRequest request,
        CancellationToken cancellationToken = default);
}
