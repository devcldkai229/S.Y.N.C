using System.Net.Http.Json;
using System.Text.Json;
using Notification.Application.Clients;
using Notification.Application.Common;
using Notification.Application.DTOs.SmartPush;

namespace Notification.Infrastructure.Clients;

public class NutritionClient : INutritionClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public NutritionClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<TodayNutritionDto?> GetTodayNutritionAsync(Guid userId, string? userLocalDate, CancellationToken cancellationToken)
    {
        var url = $"/api/internal/nutrition/summary/{userId}";
        if (!string.IsNullOrEmpty(userLocalDate))
        {
            url += $"?date={Uri.EscapeDataString(userLocalDate)}";
        }

        var response = await _httpClient.GetAsync(url, cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
        response.EnsureSuccessStatusCode();

        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<TodayNutritionDto>>(JsonOpts, cancellationToken);
        if (apiResponse == null || !apiResponse.Success || apiResponse.Data == null)
        {
            throw new HttpRequestException($"Failed to retrieve daily nutrition summary for user {userId}: {apiResponse?.Message ?? "No response"}");
        }

        return apiResponse.Data;
    }
}
