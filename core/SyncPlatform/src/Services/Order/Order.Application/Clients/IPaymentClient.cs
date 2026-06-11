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

public interface IPaymentClient
{
    Task<ChargeMealOrderResult> ChargeMealOrderAsync(
        ChargeMealOrderRequest request,
        CancellationToken cancellationToken = default);

    Task<RefundMealOrderResult> RefundMealOrderAsync(
        RefundMealOrderRequest request,
        CancellationToken cancellationToken = default);
}
