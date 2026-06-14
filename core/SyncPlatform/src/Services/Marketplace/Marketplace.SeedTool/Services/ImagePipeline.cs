using Marketplace.SeedTool.Configuration;
using Marketplace.SeedTool.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace Marketplace.SeedTool.Services;

public sealed class ImagePipeline
{
    public const string DefaultFoodKey = "food_catalog/_defaults/default_food.webp";

    private readonly IStorageService _storage;
    private readonly PexelsClient _pexels;
    private readonly StorageOptions _options;
    private readonly ILogger<ImagePipeline> _logger;
    private readonly SemaphoreSlim _defaultInitLock = new(1, 1);
    private bool _defaultEnsured;

    public ImagePipeline(
        IStorageService storage,
        PexelsClient pexels,
        IOptions<StorageOptions> options,
        ILogger<ImagePipeline> logger)
    {
        _storage = storage;
        _pexels = pexels;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ImageUploadResult> EnsureImageAsync(
        string s3Key,
        string imageQuery,
        string orientation,
        string? existingUrlOrKey,
        SeedReport report,
        CancellationToken cancellationToken = default)
    {
        s3Key = s3Key.TrimStart('/');

        if (!string.IsNullOrWhiteSpace(existingUrlOrKey) &&
            KeysMatch(existingUrlOrKey, s3Key))
        {
            report.ImagesSkipped++;
            return ImageUploadResult.Skipped(s3Key);
        }

        if (await _storage.ObjectExistsAsync(s3Key, cancellationToken))
        {
            report.ImagesSkipped++;
            return ImageUploadResult.Skipped(s3Key);
        }

        var pexelsUrl = await _pexels.SearchImageUrlAsync(imageQuery, orientation, cancellationToken);
        var raw = pexelsUrl != null
            ? await _pexels.DownloadImageAsync(pexelsUrl, cancellationToken)
            : null;

        var usedFallback = false;
        if (raw is null or { Length: 0 })
        {
            raw = await GetDefaultImageBytesAsync(cancellationToken);
            usedFallback = true;
        }

        try
        {
            var webp = await ConvertToWebpAsync(raw, orientation, cancellationToken);
            await using var stream = new MemoryStream(webp);
            await _storage.UploadFileAsync(stream, s3Key, "image/webp", cancellationToken);

            if (usedFallback)
                report.ImagesFallback++;
            else
                report.ImagesFetched++;

            return ImageUploadResult.Uploaded(s3Key);
        }
        catch (Exception ex)
        {
            report.ImagesFailed++;
            _logger.LogWarning(ex, "Failed to upload image to {Key}", s3Key);
            return ImageUploadResult.Failed(s3Key);
        }
    }

    public string ResolveStoredUrl(string s3Key)
        => _options.PublicRead ? _storage.ResolveObjectUrl(s3Key) : s3Key;

    private async Task<byte[]> GetDefaultImageBytesAsync(CancellationToken cancellationToken)
    {
        await EnsureDefaultObjectAsync(cancellationToken);

        if (await _storage.ObjectExistsAsync(DefaultFoodKey, cancellationToken))
            return await GeneratePlaceholderWebpAsync(orientation: "square", cancellationToken);

        return await GeneratePlaceholderWebpAsync(orientation: "square", cancellationToken);
    }

    private async Task EnsureDefaultObjectAsync(CancellationToken cancellationToken)
    {
        if (_defaultEnsured)
            return;

        await _defaultInitLock.WaitAsync(cancellationToken);
        try
        {
            if (_defaultEnsured)
                return;

            if (!await _storage.ObjectExistsAsync(DefaultFoodKey, cancellationToken))
            {
                var bytes = await GeneratePlaceholderWebpAsync("square", cancellationToken);
                await using var stream = new MemoryStream(bytes);
                await _storage.UploadFileAsync(stream, DefaultFoodKey, "image/webp", cancellationToken);
                _logger.LogInformation("Uploaded default food image to {Key}", DefaultFoodKey);
            }

            _defaultEnsured = true;
        }
        finally
        {
            _defaultInitLock.Release();
        }
    }

    private static async Task<byte[]> ConvertToWebpAsync(
        byte[] raw,
        string orientation,
        CancellationToken cancellationToken)
    {
        await using var input = new MemoryStream(raw);
        using var image = await Image.LoadAsync(input, cancellationToken);

        var maxSize = orientation.Equals("square", StringComparison.OrdinalIgnoreCase)
            ? new Size(512, 512)
            : new Size(1200, 800);

        image.Mutate(x => x.Resize(new ResizeOptions
        {
            Mode = ResizeMode.Max,
            Size = maxSize,
        }));

        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 82 }, cancellationToken);
        return output.ToArray();
    }

    private static async Task<byte[]> GeneratePlaceholderWebpAsync(
        string orientation,
        CancellationToken cancellationToken)
    {
        var size = orientation.Equals("landscape", StringComparison.OrdinalIgnoreCase)
            ? new Size(800, 500)
            : new Size(400, 400);

        using var image = new Image<Rgba32>(size.Width, size.Height, new Rgba32(236, 240, 241, 255));
        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 75 }, cancellationToken);
        return output.ToArray();
    }

    private static bool KeysMatch(string existing, string target)
    {
        var normalizedExisting = existing.Trim().TrimStart('/');
        var normalizedTarget = target.Trim().TrimStart('/');
        return normalizedExisting.Equals(normalizedTarget, StringComparison.OrdinalIgnoreCase)
            || normalizedExisting.EndsWith(normalizedTarget, StringComparison.OrdinalIgnoreCase);
    }

    public sealed record ImageUploadResult(string S3Key, ImageUploadStatus Status)
    {
        public static ImageUploadResult Uploaded(string key) => new(key, ImageUploadStatus.Uploaded);

        public static ImageUploadResult Skipped(string key) => new(key, ImageUploadStatus.Skipped);

        public static ImageUploadResult Failed(string key) => new(key, ImageUploadStatus.Failed);
    }

    public enum ImageUploadStatus
    {
        Uploaded,
        Skipped,
        Failed,
    }
}
