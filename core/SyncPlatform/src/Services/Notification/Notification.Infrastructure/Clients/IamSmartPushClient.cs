using System.Net.Http.Json;
using System.Text.Json;
using Notification.Application.Clients;
using Notification.Application.Common;
using Notification.Application.DTOs.SmartPush;

namespace Notification.Infrastructure.Clients;

public class IamSmartPushClient : IIamSmartPushClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public IamSmartPushClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<IReadOnlyList<DueSmartPushUserDto>> GetDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var url = $"/api/internal/smart-push/due-users?utcNow={utcNow:O}";
        var response = await _httpClient.GetAsync(url, cancellationToken);
        response.EnsureSuccessStatusCode();

        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<List<DueSmartPushUserDto>>>(JsonOpts, cancellationToken);
        if (apiResponse == null || !apiResponse.Success || apiResponse.Data == null)
        {
            throw new HttpRequestException($"Failed to retrieve due users from IAM: {apiResponse?.Message ?? "No response"}");
        }

        return apiResponse.Data;
    }

    public async Task<IamSmartPushContextDto?> GetContextAsync(Guid userId, CancellationToken cancellationToken)
    {
        var url = $"/api/internal/smart-push/context/{userId}";
        var response = await _httpClient.GetAsync(url, cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
        response.EnsureSuccessStatusCode();

        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<IamSmartPushContextDto>>(JsonOpts, cancellationToken);
        if (apiResponse == null || !apiResponse.Success || apiResponse.Data == null)
        {
            throw new HttpRequestException($"Failed to retrieve context for user {userId} from IAM: {apiResponse?.Message ?? "No response"}");
        }

        return apiResponse.Data;
    }
}
