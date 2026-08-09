using System.Net.Http.Json;
using System.Text.Json;
using Iam.Application.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Iam.Infrastructure.Clients;

public sealed class RoadmapBodyMetricsClient : IRoadmapBodyMetricsClient
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly ILogger<RoadmapBodyMetricsClient> _logger;

    public RoadmapBodyMetricsClient(
        HttpClient http,
        IConfiguration config,
        ILogger<RoadmapBodyMetricsClient> logger)
    {
        _http = http;
        _config = config;
        _logger = logger;
    }

    public async Task SyncAsync(
        Guid userId,
        decimal currentWeightKg,
        decimal? bodyFatPercentage = null,
        CancellationToken cancellationToken = default)
    {
        var baseUrl = (_config["RoadmapService:BaseUrl"] ?? "http://localhost:5118").TrimEnd('/');
        var url = $"{baseUrl}/api/internal/roadmap/users/{userId}/body-metrics";

        var body = new Dictionary<string, object?>
        {
            ["currentWeightKg"] = currentWeightKg,
        };
        if (bodyFatPercentage.HasValue)
            body["initialFatPercentage"] = bodyFatPercentage.Value;

        try
        {
            using var response = await _http.PatchAsJsonAsync(url, body, JsonOptions, cancellationToken);
            // 204 = no active roadmap (expected no-op)
            if (response.StatusCode == System.Net.HttpStatusCode.NoContent)
                return;

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Roadmap body-metrics sync returned {StatusCode} for UserId={UserId}.",
                    (int)response.StatusCode,
                    userId);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(
                ex,
                "Roadmap body-metrics sync failed for UserId={UserId}.",
                userId);
        }
    }
}
