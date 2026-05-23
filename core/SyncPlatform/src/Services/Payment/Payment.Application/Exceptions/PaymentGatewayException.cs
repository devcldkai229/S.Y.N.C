namespace Payment.Application.Exceptions;

/// <summary>Thrown when an upstream payment provider (PayOS, GooglePlay, ...) returns an error.</summary>
public class PaymentGatewayException : AppException
{
    public PaymentGatewayException(string message) : base(message) { }
    public PaymentGatewayException(string message, Exception inner) : base(message, inner) { }
}
