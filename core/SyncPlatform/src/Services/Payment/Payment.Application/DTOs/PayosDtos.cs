using System.ComponentModel.DataAnnotations;

namespace Payment.Application.DTOs;

public enum BillingCycle
{
    Monthly = 0,
    Yearly  = 1
}

public class CreatePaymentLinkRequest
{
    [Required]
    public Guid PlanId { get; set; }

    public BillingCycle BillingCycle { get; set; } = BillingCycle.Monthly;
}

public class CreatePaymentLinkResponse
{
    public long OrderCode { get; set; }
    public Guid TransactionId { get; set; }
    public int Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public string CheckoutUrl { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;
    public string? PaymentLinkId { get; set; }
    public string? AccountNumber { get; set; }
    public string? Bin { get; set; }
    public string? Status { get; set; }
    public long? ExpiredAt { get; set; }
}

public enum WebhookProcessOutcome
{
    Processed = 0,
    AlreadyProcessed = 1,
    TransactionNotFound = 2,
    TransactionAlreadyFinal = 3,
    PaymentFailed = 4
}

public class PayosWebhookProcessResult
{
    public WebhookProcessOutcome Outcome { get; set; }
    public long OrderCode { get; set; }
    public string Message { get; set; } = string.Empty;
}
