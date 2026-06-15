using Libs.Shared.Seed;
using Libs.Storage.Services;
using Microsoft.Extensions.Logging;

namespace Social.Infrastructure.Persistence.Seed;

/// <summary>
/// Uploads tiny placeholder images to S3 so dev seed URLs resolve via the gateway media proxy.
/// </summary>
public class S3DevAssetSeeder
{
    private static readonly byte[] PlaceholderPng = Convert.FromBase64String(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");

    private readonly S3ObjectStorage _storage;
    private readonly ILogger<S3DevAssetSeeder> _logger;

    public S3DevAssetSeeder(S3ObjectStorage storage, ILogger<S3DevAssetSeeder> logger)
    {
        _storage = storage;
        _logger = logger;
    }

    public async Task SeedPlaceholdersAsync(CancellationToken cancellationToken = default)
    {
        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(15));

        try
        {
            foreach (var key in DevSeedMediaUrls.SeedObjectKeys)
            {
                timeoutCts.Token.ThrowIfCancellationRequested();

                if (await _storage.ObjectExistsAsync(key, timeoutCts.Token))
                    continue;

                await using var stream = new MemoryStream(PlaceholderPng);
                await _storage.UploadAsync(stream, PlaceholderPng.Length, key, "image/png", timeoutCts.Token);
                _logger.LogInformation("S3 dev seed: uploaded placeholder {Key}", key);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning(
                "S3 dev seed timed out after 15s (bucket {Bucket}). Social API will start without placeholder assets.",
                _storage.Options.Bucket);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "S3 dev seed skipped (bucket {Bucket}). Social API will start without placeholder assets.",
                _storage.Options.Bucket);
        }
    }
}
