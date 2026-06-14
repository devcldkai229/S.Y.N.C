using Exercise.Application.Configuration;
using Exercise.Application.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;

namespace Exercise.ImportTool.Services;

public sealed class ExerciseMediaPipeline
{
    private readonly IStorageService _storage;
    private readonly StorageOptions _options;
    private readonly FreeExerciseDbFetcher _fetcher;
    private readonly ILogger<ExerciseMediaPipeline> _logger;

    public ExerciseMediaPipeline(
        IStorageService storage,
        IOptions<StorageOptions> options,
        FreeExerciseDbFetcher fetcher,
        ILogger<ExerciseMediaPipeline> logger)
    {
        _storage = storage;
        _options = options.Value;
        _fetcher = fetcher;
        _logger = logger;
    }

    public sealed record UploadedImage(string S3Key, bool IsPrimary);

    public async Task<IReadOnlyList<UploadedImage>> ProcessAndUploadAsync(
        string slug,
        IReadOnlyList<string> imagePaths,
        CancellationToken cancellationToken = default)
    {
        var results = new List<UploadedImage>();
        if (imagePaths.Count == 0) return results;

        for (var index = 0; index < imagePaths.Count; index++)
        {
            var raw = await _fetcher.DownloadImageAsync(imagePaths[index], cancellationToken);
            if (raw == null || raw.Length == 0) continue;

            try
            {
                await using var input = new MemoryStream(raw);
                using var image = await Image.LoadAsync(input, cancellationToken);

                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Mode = ResizeMode.Max,
                    Size = new Size(800, 800),
                }));

                await using var output = new MemoryStream();
                await image.SaveAsync(output, new WebpEncoder { Quality = 82 }, cancellationToken);
                output.Position = 0;

                var key = $"{_options.KeyPrefix.TrimEnd('/')}/{slug}/{index}.webp";
                await _storage.UploadFileAsync(output, key, "image/webp", cancellationToken);
                results.Add(new UploadedImage(key, index == 0));
                _logger.LogDebug("Uploaded {Key}", key);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Image processing failed for {Slug} index {Index}", slug, index);
            }
        }

        return results;
    }
}
