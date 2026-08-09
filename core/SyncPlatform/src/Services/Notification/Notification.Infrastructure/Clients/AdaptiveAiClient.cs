using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Notification.Application.Clients;

namespace Notification.Infrastructure.Clients;

public sealed class AdaptiveAiClient : IAdaptiveAiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AdaptiveAiClient> _logger;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public AdaptiveAiClient(HttpClient httpClient, ILogger<AdaptiveAiClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task TriggerWeeklyRecalcAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken = default)
    {
        if (userIds.Count == 0)
            return;

        // Soft-cap matches AI endpoint (50 per request).
        for (var i = 0; i < userIds.Count; i += 50)
        {
            var batch = userIds.Skip(i).Take(50).Select(id => id.ToString()).ToList();
            var payload = new { user_ids = batch, trigger = "Weekly" };
            using var response = await _httpClient.PostAsJsonAsync(
                "/ai/internal/adaptive/weekly-recalc",
                payload,
                JsonOpts,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogWarning(
                    "Adaptive weekly-recalc batch failed: {Status} {Body}",
                    (int)response.StatusCode,
                    body.Length > 300 ? body[..300] : body);
                continue;
            }

            _logger.LogInformation("Adaptive weekly-recalc submitted for {Count} users.", batch.Count);
        }
    }
}
