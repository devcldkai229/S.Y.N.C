using Iam.Application.Abstractions;
using Microsoft.Extensions.Logging;

namespace Iam.Infrastructure.Clients;

public sealed class RoadmapClient : IRoadmapClient
{
    private readonly HttpClient _http;
    private readonly ILogger<RoadmapClient> _logger;

    public RoadmapClient(HttpClient http, ILogger<RoadmapClient> logger)
    {
        _http = http;
        _logger = logger;
    }

    public async Task EnsureAuditRoadmapAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _http.PostAsync(
                $"/api/internal/roadmap/users/{userId}/bootstrap-audit",
                content: null,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogWarning(
                    "Roadmap bootstrap-audit returned {Status} for UserId={UserId}. Body: {Body}",
                    (int)response.StatusCode,
                    userId,
                    body);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Roadmap bootstrap-audit failed for UserId={UserId}", userId);
        }
    }
}
