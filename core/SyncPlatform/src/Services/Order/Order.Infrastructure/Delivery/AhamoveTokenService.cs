using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Delivery;

public sealed class AhamoveTokenService
{
    private const string CacheKey = "ahamove:bearer-token";
    private static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(45);

    private readonly HttpClient _http;
    private readonly AhamoveSettings _settings;
    private readonly IMemoryCache _cache;
    private readonly ILogger<AhamoveTokenService> _logger;

    public AhamoveTokenService(
        HttpClient http,
        IOptions<AhamoveSettings> settings,
        IMemoryCache cache,
        ILogger<AhamoveTokenService> logger)
    {
        _http = http;
        _settings = settings.Value;
        _cache = cache;
        _logger = logger;
    }

    public async Task<string> GetTokenAsync(CancellationToken cancellationToken = default)
    {
        if (_cache.TryGetValue(CacheKey, out string? cached) && !string.IsNullOrWhiteSpace(cached))
            return cached;

        var mobile = AhamovePhone.Normalize(_settings.Mobile);
        if (string.IsNullOrWhiteSpace(mobile))
            throw new InvalidOperationException("Ahamove:Mobile is required when Ahamove is enabled.");

        var baseUrl = ResolveBaseUrl(_settings.BaseUrl);
        var payload = JsonSerializer.Serialize(new { mobile, api_key = _settings.ApiKey });
        using var content = new StringContent(payload, Encoding.UTF8, "application/json");
        using var response = await _http.PostAsync($"{baseUrl}/accounts/token", content, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("Ahamove token request failed ({Status}): {Body}", response.StatusCode, body);
            throw new InvalidOperationException($"Ahamove token request failed: {response.StatusCode}");
        }

        using var doc = JsonDocument.Parse(body);
        var token = doc.RootElement.GetProperty("token").GetString()
            ?? throw new InvalidOperationException("Ahamove token response missing token.");

        _cache.Set(CacheKey, token, TokenLifetime);
        return token;
    }

    internal static string ResolveBaseUrl(string? configured) =>
        string.IsNullOrWhiteSpace(configured)
            ? "https://partner-apistg.ahamove.com/v3"
            : configured.TrimEnd('/');
}
