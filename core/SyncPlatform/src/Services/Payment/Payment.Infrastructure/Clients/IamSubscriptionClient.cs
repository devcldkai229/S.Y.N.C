using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Payment.Application.Clients;

namespace Payment.Infrastructure.Clients;

public class IamSubscriptionClient : IIamSubscriptionClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<IamSubscriptionClient> _logger;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public IamSubscriptionClient(HttpClient httpClient, ILogger<IamSubscriptionClient> logger)
    {
        _httpClient = httpClient;
        _logger     = logger;
    }

    public async Task SetTierAsync(Guid userId, string tier, CancellationToken cancellationToken = default)
    {
        var payload = new { userId, tier };

        var response = await _httpClient.PostAsJsonAsync(
            "/api/internal/subscriptions/tier",
            payload,
            JsonOpts,
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning(
                "IAM SetTier returned {Status} for UserId={UserId}, Tier={Tier}. Body: {Body}",
                (int)response.StatusCode, userId, tier, body);
        }
    }
}
