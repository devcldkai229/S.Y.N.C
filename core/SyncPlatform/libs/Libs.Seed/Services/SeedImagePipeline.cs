using Libs.Seed.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Libs.Seed.Services;

public sealed class SeedImagePipeline
{
    public const string DefaultFoodKey = "food_catalog/_defaults/default_food.webp";

    private readonly IS3SeedStorage _storage;
    private readonly PexelsClient _pexels;
    private readonly SeedStorageOptions _options;
    private readonly ILogger<SeedImagePipeline> _logger;
    private readonly string _assetsRoot;
    private readonly SemaphoreSlim _defaultLock = new(1, 1);
    private bool _defaultEnsured;

    public SeedImagePipeline(
        IS3SeedStorage storage,
        PexelsClient pexels,
        IOptions<SeedStorageOptions> options,
        ILogger<SeedImagePipeline> logger)
    {
        _storage = storage;
        _pexels = pexels;
        _options = options.Value;
        _logger = logger;
        _assetsRoot = Path.Combine(AppContext.BaseDirectory, "assets");
    }

    public static string AvatarKey(Guid userId) => $"avatars/{userId}.webp";

    public static string AvatarKey(string userId) => $"avatars/{userId}.webp";

    public string ResolveStored(string s3Key) => _storage.ResolveStoredValue(s3Key);

    public async Task<string> GenerateAvatarAsync(
        Guid userId,
        string fullName,
        SeedImageStats? stats = null,
        CancellationToken cancellationToken = default)
    {
        var key = AvatarKey(userId);
        if (await _storage.ObjectExistsAsync(key, cancellationToken))
        {
            stats?.IncSkipped();
            return ResolveStored(key);
        }

        try
        {
            var webp = await ImageProcessor.GenerateAvatarWebpAsync(userId, fullName, cancellationToken);
            await using var stream = new MemoryStream(webp);
            await _storage.UploadAsync(stream, key, "image/webp", cancellationToken);
            stats?.IncUploaded();
            return ResolveStored(key);
        }
        catch (Exception ex)
        {
            stats?.IncFailed();
            _logger.LogWarning(ex, "Avatar generation failed for {UserId}", userId);
            return ResolveStored(key);
        }
    }

    public async Task<string> PexelsQueryAsync(
        string s3Key,
        string keywords,
        string orientation = "landscape",
        CancellationToken cancellationToken = default,
        SeedImageStats? stats = null)
    {
        s3Key = PrefixKey(s3Key);
        if (await _storage.ObjectExistsAsync(s3Key, cancellationToken))
        {
            stats?.IncSkipped();
            return ResolveStored(s3Key);
        }

        try
        {
            var pexelsUrl = await _pexels.SearchImageUrlAsync(keywords, orientation, cancellationToken);
            var raw = pexelsUrl != null
                ? await _pexels.DownloadImageAsync(pexelsUrl, cancellationToken)
                : null;

            var usedFallback = raw is null or { Length: 0 };
            if (usedFallback)
            {
                raw = await EnsureDefaultFoodBytesAsync(cancellationToken);
                stats?.IncFallback();
            }
            else
            {
                stats?.IncUploaded();
            }

            var webp = await ImageProcessor.ToWebpAsync(raw, orientation, cancellationToken: cancellationToken);
            await using var stream = new MemoryStream(webp);
            await _storage.UploadAsync(stream, s3Key, "image/webp", cancellationToken);
            return ResolveStored(s3Key);
        }
        catch (Exception ex)
        {
            stats?.IncFailed();
            _logger.LogWarning(ex, "Pexels upload failed for {Key}", s3Key);
            return ResolveStored(DefaultFoodKey);
        }
    }

    public async Task<string> AssetAsync(
        string relativePath,
        string fallbackLabel,
        CancellationToken cancellationToken = default,
        SeedImageStats? stats = null)
    {
        var key = PrefixKey(relativePath.Replace('\\', '/').TrimStart('/'));
        if (key.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
            key = Path.ChangeExtension(key, ".webp").Replace('\\', '/');

        if (await _storage.ObjectExistsAsync(key, cancellationToken))
        {
            stats?.IncSkipped();
            return ResolveStored(key);
        }

        try
        {
            byte[] webp;
            var localPath = Path.Combine(_assetsRoot, relativePath);
            if (File.Exists(localPath))
            {
                var raw = await File.ReadAllBytesAsync(localPath, cancellationToken);
                webp = await ImageProcessor.ToWebpAsync(raw, "square", cancellationToken: cancellationToken);
            }
            else
            {
                _logger.LogWarning("Asset missing at {Path}; generating medal fallback", localPath);
                webp = await ImageProcessor.GenerateMedalWebpAsync(fallbackLabel, cancellationToken);
                stats?.IncFallback();
            }

            await using var stream = new MemoryStream(webp);
            await _storage.UploadAsync(stream, key, "image/webp", cancellationToken);
            if (File.Exists(localPath))
                stats?.IncUploaded();
            return ResolveStored(key);
        }
        catch (Exception ex)
        {
            stats?.IncFailed();
            _logger.LogWarning(ex, "Asset upload failed for {Key}", key);
            return ResolveStored(key);
        }
    }

    public async Task<string> ImportAsync(
        string s3Key,
        string sourceUrl,
        string orientation = "landscape",
        CancellationToken cancellationToken = default,
        SeedImageStats? stats = null)
    {
        s3Key = PrefixKey(s3Key);
        if (await _storage.ObjectExistsAsync(s3Key, cancellationToken))
        {
            stats?.IncSkipped();
            return ResolveStored(s3Key);
        }

        try
        {
            var raw = await _pexels.DownloadImageAsync(sourceUrl, cancellationToken);
            if (raw is null or { Length: 0 })
            {
                stats?.IncFallback();
                raw = await EnsureDefaultFoodBytesAsync(cancellationToken);
            }
            else
            {
                stats?.IncUploaded();
            }

            var webp = await ImageProcessor.ToWebpAsync(raw, orientation, cancellationToken: cancellationToken);
            await using var stream = new MemoryStream(webp);
            await _storage.UploadAsync(stream, s3Key, "image/webp", cancellationToken);
            return ResolveStored(s3Key);
        }
        catch (Exception ex)
        {
            stats?.IncFailed();
            _logger.LogWarning(ex, "Import failed for {Key}", s3Key);
            return ResolveStored(s3Key);
        }
    }

    private string PrefixKey(string key)
    {
        key = key.TrimStart('/');
        if (string.IsNullOrWhiteSpace(_options.KeyPrefix))
            return key;

        var prefix = _options.KeyPrefix.TrimEnd('/');
        return key.StartsWith(prefix, StringComparison.OrdinalIgnoreCase) ? key : $"{prefix}/{key}";
    }

    private async Task<byte[]> EnsureDefaultFoodBytesAsync(CancellationToken cancellationToken)
    {
        await EnsureDefaultObjectAsync(cancellationToken);
        return await ImageProcessor.GeneratePlaceholderWebpAsync("square", cancellationToken);
    }

    private async Task EnsureDefaultObjectAsync(CancellationToken cancellationToken)
    {
        if (_defaultEnsured)
            return;

        await _defaultLock.WaitAsync(cancellationToken);
        try
        {
            if (_defaultEnsured)
                return;

            if (!await _storage.ObjectExistsAsync(DefaultFoodKey, cancellationToken))
            {
                var bytes = await ImageProcessor.GeneratePlaceholderWebpAsync("square", cancellationToken);
                await using var stream = new MemoryStream(bytes);
                await _storage.UploadAsync(stream, DefaultFoodKey, "image/webp", cancellationToken);
            }

            _defaultEnsured = true;
        }
        finally
        {
            _defaultLock.Release();
        }
    }
}

public sealed class SeedImageStats
{
    public int Uploaded { get; set; }
    public int Skipped { get; set; }
    public int Failed { get; set; }
    public int Fallback { get; set; }

    public void IncUploaded() => Uploaded++;
    public void IncSkipped() => Skipped++;
    public void IncFailed() => Failed++;
    public void IncFallback() => Fallback++;
}
