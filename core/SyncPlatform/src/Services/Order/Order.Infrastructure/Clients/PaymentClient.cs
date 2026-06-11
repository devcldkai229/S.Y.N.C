using System.Net.Http.Json;
using System.Text.Json;
using Order.Application.Clients;
using Order.Application.Common;

namespace Order.Infrastructure.Clients;

public class PaymentClient : IPaymentClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public PaymentClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<ChargeMealOrderResult> ChargeMealOrderAsync(
        ChargeMealOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/wallet/charge-meal-order", request, JsonOpts, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return new ChargeMealOrderResult { Success = false, FailureReason = "Payment service rejected the charge." };
        }

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<ChargeMealOrderResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new ChargeMealOrderResult { Success = false, FailureReason = "Empty payment response." };
    }

    public async Task<RefundMealOrderResult> RefundMealOrderAsync(
        RefundMealOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/wallet/refund-meal-order", request, JsonOpts, cancellationToken);
        if (!response.IsSuccessStatusCode)
            return new RefundMealOrderResult { Success = false, FailureReason = "Refund failed." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<RefundMealOrderResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new RefundMealOrderResult { Success = false };
    }
}
