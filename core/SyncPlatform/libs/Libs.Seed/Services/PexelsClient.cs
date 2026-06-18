using System.Text.Json;
using Libs.Seed.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Libs.Seed.Services;

public sealed class PexelsClient
{
    private const string SearchUrl = "https://api.pexels.com/v1/search";

    private readonly HttpClient _http;
    private readonly PexelsOptions _options;
    private readonly ILogger<PexelsClient> _logger;
    private readonly SemaphoreSlim _rateGate = new(1, 1);
    private readonly Dictionary<string, string?> _queryCache = new(StringComparer.OrdinalIgnoreCase);

    public PexelsClient(HttpClient http, IOptions<PexelsOptions> options, ILogger<PexelsClient> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_options.ApiKey);

    public async Task<string?> SearchImageUrlAsync(
        string query,
        string orientation,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
            return null;

        var cacheKey = $"{orientation}:{query}";
        if (_queryCache.TryGetValue(cacheKey, out var cached))
            return cached;

        if (!IsConfigured)
        {
            _logger.LogWarning("Pexels ApiKey not configured; image queries will use fallback.");
            _queryCache[cacheKey] = null;
            return null;
        }

        await _rateGate.WaitAsync(cancellationToken);
        try
        {
            if (_queryCache.TryGetValue(cacheKey, out cached))
                return cached;

            var url = await FetchWithRetryAsync(query, orientation, cancellationToken);
            _queryCache[cacheKey] = url;
            return url;
        }
        finally
        {
            _rateGate.Release();
        }
    }

    public async Task<byte[]?> DownloadImageAsync(string imageUrl, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(imageUrl))
            return null;

        for (var attempt = 1; attempt <= _options.MaxRetries; attempt++)
        {
            try
            {
                using var response = await _http.GetAsync(imageUrl, cancellationToken);
                if (response.IsSuccessStatusCode)
                    return await response.Content.ReadAsByteArrayAsync(cancellationToken);

                _logger.LogWarning("Image download failed ({Status}) attempt {Attempt}", response.StatusCode, attempt);
            }
            catch (Exception ex) when (attempt < _options.MaxRetries)
            {
                _logger.LogWarning(ex, "Image download error attempt {Attempt}", attempt);
            }

            await Task.Delay(_options.MinDelayMs * attempt, cancellationToken);
        }

        return null;
    }

    private async Task<string?> FetchWithRetryAsync(
        string query,
        string orientation,
        CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= _options.MaxRetries; attempt++)
        {
            try
            {
                var uri = $"{SearchUrl}?query={Uri.EscapeDataString(query)}&per_page=1&orientation={orientation}";
                using var request = new HttpRequestMessage(HttpMethod.Get, uri);
                request.Headers.Add("Authorization", _options.ApiKey);

                using var response = await _http.SendAsync(request, cancellationToken);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Pexels search failed ({Status}) for '{Query}' attempt {Attempt}",
                        response.StatusCode, query, attempt);
                }
                else
                {
                    await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
                    using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
                    var photos = doc.RootElement.GetProperty("photos");
                    if (photos.GetArrayLength() == 0)
                        return null;

                    var src = photos[0].GetProperty("src");
                    return orientation.Equals("portrait", StringComparison.OrdinalIgnoreCase)
                        ? src.GetProperty("portrait").GetString()
                        : orientation.Equals("square", StringComparison.OrdinalIgnoreCase)
                            ? src.GetProperty("medium").GetString()
                            : src.GetProperty("large").GetString();
                }
            }
            catch (Exception ex) when (attempt < _options.MaxRetries)
            {
                _logger.LogWarning(ex, "Pexels search error for '{Query}' attempt {Attempt}", query, attempt);
            }

            await Task.Delay(_options.MinDelayMs * attempt, cancellationToken);
        }

        return null;
    }
}
