using System.Net.Http.Json;
using Order.Application.Clients;

namespace Order.Infrastructure.Clients;

public class NotificationClient : INotificationClient
{
    private readonly HttpClient _httpClient;

    public NotificationClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task SendOrderStatusAsync(
        Guid userId,
        string title,
        string body,
        Guid orderId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _httpClient.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId,
                    type = "MealAutoOrder",
                    channel = "InApp",
                    priority = "Normal",
                    title,
                    body,
                    deepLink = $"/orders/{orderId}",
                },
                cancellationToken);
        }
        catch
        {
            // best-effort
        }
    }
}
