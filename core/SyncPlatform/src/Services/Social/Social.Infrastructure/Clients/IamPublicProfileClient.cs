using System.Net.Http.Json;
using Social.Application.Clients;

namespace Social.Infrastructure.Clients;

public sealed class IamPublicProfileClient : IIamPublicProfileClient
{
    private readonly HttpClient _http;

    public IamPublicProfileClient(HttpClient http) => _http = http;

    public async Task<IamPublicProfile?> GetAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _http.GetFromJsonAsync<ApiEnvelope>(
                $"/api/v1/users/{userId}/public-profile",
                cancellationToken);

            if (response is null || !response.Success || response.Data is null)
                return null;

            return new IamPublicProfile
            {
                UserId = response.Data.UserId,
                FullName = string.IsNullOrWhiteSpace(response.Data.FullName)
                    ? "Người dùng"
                    : response.Data.FullName,
                AvatarUrl = response.Data.AvatarUrl,
            };
        }
        catch
        {
            return null;
        }
    }

    private sealed class ApiEnvelope
    {
        public bool Success { get; set; }
        public PublicProfilePayload? Data { get; set; }
    }

    private sealed class PublicProfilePayload
    {
        public Guid UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
    }
}
