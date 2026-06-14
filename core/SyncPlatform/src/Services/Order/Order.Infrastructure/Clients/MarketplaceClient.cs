using System.Net.Http.Json;
using System.Text.Json;
using Order.Application.Clients;
using Order.Application.Common;

namespace Order.Infrastructure.Clients;

public class MarketplaceClient : IMarketplaceClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public MarketplaceClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<ValidateOrderItemsResult> ValidateOrderItemsAsync(
        ValidateOrderItemsRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(
                "/api/internal/food-menu/validate-order",
                request,
                JsonOpts,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                return new ValidateOrderItemsResult
                {
                    IsValid = false,
                    ErrorMessage = $"Marketplace validation failed ({(int)response.StatusCode}).",
                };
            }

            var api = await response.Content.ReadFromJsonAsync<ApiResponse<ValidateOrderItemsResult>>(JsonOpts, cancellationToken);
            return api?.Data ?? new ValidateOrderItemsResult { IsValid = false, ErrorMessage = "Validation failed." };
        }
        catch (Exception ex)
        {
            return new ValidateOrderItemsResult
            {
                IsValid = false,
                ErrorMessage = $"Marketplace service unavailable: {ex.Message}",
            };
        }
    }

    public async Task<PartnerInternalDto?> GetPartnerAsync(Guid partnerId, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"/api/internal/partners/{partnerId}", cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return null;
        response.EnsureSuccessStatusCode();
        var api = await response.Content.ReadFromJsonAsync<ApiResponse<PartnerInternalDto>>(JsonOpts, cancellationToken);
        return api?.Data;
    }
}
