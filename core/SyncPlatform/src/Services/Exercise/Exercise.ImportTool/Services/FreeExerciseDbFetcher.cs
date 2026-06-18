using System.Net;
using System.Text.Json;
using Exercise.Application.Configuration;
using Exercise.ImportTool.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Exercise.ImportTool.Services;

public sealed class FreeExerciseDbFetcher
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly HttpClient _http;
    private readonly FreeExerciseDbOptions _options;
    private readonly ILogger<FreeExerciseDbFetcher> _logger;

    public FreeExerciseDbFetcher(HttpClient http, IOptions<FreeExerciseDbOptions> options, ILogger<FreeExerciseDbFetcher> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<IReadOnlyList<FreeExerciseDbEntry>> FetchCatalogAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Downloading catalog from {Url}", _options.JsonUrl);
        var json = await GetWithRetryAsync(_options.JsonUrl, cancellationToken);
        var entries = JsonSerializer.Deserialize<List<FreeExerciseDbEntry>>(json, JsonOptions) ?? [];
        _logger.LogInformation("Loaded {Count} exercises from Free Exercise DB", entries.Count);
        return entries;
    }

    public async Task<byte[]?> DownloadImageAsync(string imagePath, CancellationToken cancellationToken = default)
    {
        var url = $"{_options.ImageBaseUrl.TrimEnd('/')}/{imagePath.TrimStart('/')}";
        try
        {
            return await GetBytesWithRetryAsync(url, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to download image {Path}", imagePath);
            return null;
        }
    }

    private async Task<string> GetWithRetryAsync(string url, CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= 5; attempt++)
        {
            try
            {
                using var response = await _http.GetAsync(url, cancellationToken);
                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    await DelayBackoffAsync(attempt, cancellationToken);
                    continue;
                }

                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync(cancellationToken);
            }
            catch (Exception) when (attempt < 5)
            {
                await DelayBackoffAsync(attempt, cancellationToken);
            }
        }

        throw new InvalidOperationException($"Failed to download {url} after retries.");
    }

    private async Task<byte[]> GetBytesWithRetryAsync(string url, CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= 4; attempt++)
        {
            try
            {
                await Task.Delay(120 * attempt, cancellationToken);
                using var response = await _http.GetAsync(url, cancellationToken);
                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    await DelayBackoffAsync(attempt, cancellationToken);
                    continue;
                }

                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsByteArrayAsync(cancellationToken);
            }
            catch (Exception) when (attempt < 4)
            {
                await DelayBackoffAsync(attempt, cancellationToken);
            }
        }

        throw new InvalidOperationException($"Failed to download bytes from {url}");
    }

    private static async Task DelayBackoffAsync(int attempt, CancellationToken cancellationToken)
    {
        var delay = TimeSpan.FromMilliseconds(400 * Math.Pow(2, attempt - 1));
        await Task.Delay(delay, cancellationToken);
    }
}
