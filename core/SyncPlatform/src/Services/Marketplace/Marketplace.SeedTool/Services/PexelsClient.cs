using System.Text.Json;
using Marketplace.SeedTool.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Marketplace.SeedTool.Services;

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

        if (_queryCache.TryGetValue($"{orientation}:{query}", out var cached))
            return cached;

        if (!IsConfigured)
        {
            _logger.LogWarning("Pexels ApiKey not configured; using fallback images.");
            _queryCache[$"{orientation}:{query}"] = null;
            return null;
        }

        await _rateGate.WaitAsync(cancellationToken);
        try
        {
            if (_queryCache.TryGetValue($"{orientation}:{query}", out cached))
                return cached;

            var url = await FetchWithRetryAsync(query, orientation, cancellationToken);
            _queryCache[$"{orientation}:{query}"] = url;
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
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Image download failed ({Status}) attempt {Attempt}: {Url}",
                        response.StatusCode, attempt, imageUrl);
                }
                else
                {
                    return await response.Content.ReadAsByteArrayAsync(cancellationToken);
                }
            }
            catch (Exception ex) when (attempt < _options.MaxRetries)
            {
                _logger.LogWarning(ex, "Image download error attempt {Attempt}", attempt);
            }

            await Task.Delay(TimeSpan.FromMilliseconds(250 * attempt), cancellationToken);
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
                using var request = new HttpRequestMessage(
                    HttpMethod.Get,
                    $"{SearchUrl}?query={Uri.EscapeDataString(query)}&per_page=3&orientation={orientation}");

                request.Headers.TryAddWithoutValidation("Authorization", _options.ApiKey);

                using var response = await _http.SendAsync(request, cancellationToken);
                if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                {
                    var retryAfter = response.Headers.RetryAfter?.Delta ?? TimeSpan.FromSeconds(2 * attempt);
                    _logger.LogWarning("Pexels rate limited; waiting {Seconds}s", retryAfter.TotalSeconds);
                    await Task.Delay(retryAfter, cancellationToken);
                    continue;
                }

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Pexels search failed ({Status}) for '{Query}' attempt {Attempt}",
                        response.StatusCode, query, attempt);
                }
                else
                {
                    await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
                    using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

                    if (doc.RootElement.TryGetProperty("photos", out var photos) &&
                        photos.GetArrayLength() > 0 &&
                        photos[0].TryGetProperty("src", out var src) &&
                        src.TryGetProperty("large", out var large))
                    {
                        var imageUrl = large.GetString();
                        if (!string.IsNullOrWhiteSpace(imageUrl))
                        {
                            await Task.Delay(_options.MinDelayMs, cancellationToken);
                            return imageUrl;
                        }
                    }

                    _logger.LogWarning("Pexels returned no photos for '{Query}'", query);
                    return null;
                }
            }
            catch (Exception ex) when (attempt < _options.MaxRetries)
            {
                _logger.LogWarning(ex, "Pexels search error for '{Query}' attempt {Attempt}", query, attempt);
            }

            await Task.Delay(TimeSpan.FromMilliseconds(400 * attempt), cancellationToken);
        }

        return null;
    }
}
