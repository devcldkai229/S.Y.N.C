namespace Order.Application.Clients;

public interface INotificationClient
{
    Task SendOrderStatusAsync(
        Guid userId,
        string title,
        string body,
        Guid orderId,
        CancellationToken cancellationToken = default);
}
