namespace Payment.Application.Clients;

public interface IOrderPaymentNotifyClient
{
    Task ConfirmOrderPaymentAsync(Guid orderId, Guid transactionId, CancellationToken cancellationToken = default);
}
