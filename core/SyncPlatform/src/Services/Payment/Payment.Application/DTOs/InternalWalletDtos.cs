namespace Payment.Application.DTOs;

public class ChargeMealOrderRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";

    public Guid? VoucherId { get; set; }

    public bool IsAiInitiated { get; set; }
}

public class ChargeMealOrderResponseDto
{
    public bool Success { get; set; }

    public Guid? TransactionId { get; set; }

    public decimal DiscountAmount { get; set; }

    public string? FailureReason { get; set; }
}

public class RefundMealOrderRequestDto
{
    public Guid UserId { get; set; }

    public Guid OrderId { get; set; }

    public Guid? OriginalTransactionId { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";
}

public class RefundMealOrderResponseDto
{
    public bool Success { get; set; }

    public Guid? RefundTransactionId { get; set; }

    public string? FailureReason { get; set; }
}
