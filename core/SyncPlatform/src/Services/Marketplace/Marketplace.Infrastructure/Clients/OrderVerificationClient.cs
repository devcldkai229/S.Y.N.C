using System.Net.Http.Json;
using System.Text.Json;
using Marketplace.Application.Clients;
using Marketplace.Application.Common;
using Marketplace.Domain.Enums;

namespace Marketplace.Infrastructure.Clients;

public class OrderVerificationClient : IOrderVerificationClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public OrderVerificationClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<OrderVerificationResult> VerifyPurchaseAsync(
        Guid userId,
        ReviewTargetType targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default)
    {
        var query = $"userId={userId}&targetType={targetType}&targetId={targetId}";
        if (orderId.HasValue)
            query += $"&orderId={orderId.Value}";

        var response = await _httpClient.GetAsync($"/api/internal/orders/verify-purchase?{query}", cancellationToken);
        if (!response.IsSuccessStatusCode)
            return new OrderVerificationResult();

        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<OrderVerificationResult>>(JsonOpts, cancellationToken);
        return apiResponse?.Data ?? new OrderVerificationResult();
    }
}
