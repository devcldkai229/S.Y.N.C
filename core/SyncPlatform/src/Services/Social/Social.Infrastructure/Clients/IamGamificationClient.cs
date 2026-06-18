using System.Net.Http.Json;
using Social.Application.Clients;

namespace Social.Infrastructure.Clients;

public sealed class IamGamificationClient : IIamGamificationClient
{
    private readonly HttpClient _http;

    public IamGamificationClient(HttpClient http) => _http = http;

    public async Task GrantXpAsync(
        Guid userId, int xp, int coins, string eventName,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _http.PostAsJsonAsync(
                "/api/internal/gamification/grant",
                new { userId, xp, coins, eventName },
                cancellationToken);
        }
        catch
        {
            // Gamification is best-effort — never fail the caller
        }
    }
}
