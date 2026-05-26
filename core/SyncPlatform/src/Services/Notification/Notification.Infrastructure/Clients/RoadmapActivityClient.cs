using System.Net.Http.Json;
using System.Text.Json;
using Notification.Application.Clients;
using Notification.Application.Common;
using Notification.Application.DTOs.SmartPush;

namespace Notification.Infrastructure.Clients;

public class RoadmapActivityClient : IRoadmapActivityClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public RoadmapActivityClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<TodayWorkoutActivityDto?> GetTodayActivityAsync(Guid userId, string timeZoneId, CancellationToken cancellationToken)
    {
        var url = $"/api/internal/workout-activity/today/{userId}?timeZoneId={Uri.EscapeDataString(timeZoneId)}";
        var response = await _httpClient.GetAsync(url, cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
        response.EnsureSuccessStatusCode();

        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<TodayWorkoutActivityDto>>(JsonOpts, cancellationToken);
        if (apiResponse == null || !apiResponse.Success || apiResponse.Data == null)
        {
            throw new HttpRequestException($"Failed to retrieve workout activity for user {userId} from Roadmap: {apiResponse?.Message ?? "No response"}");
        }

        return apiResponse.Data;
    }
}
