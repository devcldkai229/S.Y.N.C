using System.Net.Http.Json;
using System.Text.Json;
using Marketplace.Application.Clients;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;

namespace Marketplace.Infrastructure.Clients;

public class IamUserClient : IIamUserClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public IamUserClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<AuthorSnapshotDto?> GetAuthorSnapshotAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"/api/internal/users/{userId}/author-snapshot", cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return null;

        response.EnsureSuccessStatusCode();
        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<AuthorSnapshotDto>>(JsonOpts, cancellationToken);
        return apiResponse?.Data;
    }
}
