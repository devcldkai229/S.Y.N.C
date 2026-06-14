using System.Net.Http.Json;
using Payment.Application.Clients;

namespace Payment.Infrastructure.Clients;

public class OrderPaymentNotifyClient : IOrderPaymentNotifyClient
{
    private readonly HttpClient _httpClient;

    public OrderPaymentNotifyClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task ConfirmOrderPaymentAsync(Guid orderId, Guid transactionId, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync(
            $"/api/internal/orders/{orderId:D}/confirm-payment",
            new { transactionId },
            cancellationToken);
        response.EnsureSuccessStatusCode();
    }
}
