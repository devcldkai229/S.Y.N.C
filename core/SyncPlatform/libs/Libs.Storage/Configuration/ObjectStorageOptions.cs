using Libs.Shared.Storage;

namespace Libs.Storage.Configuration;

public class ObjectStorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = StorageBuckets.PublicAssets;

    /// <summary>Gateway media base URL, e.g. http://localhost:5057/api/v1/media</summary>
    public string PublicBaseUrl { get; set; } = "http://localhost:5057/api/v1/media";

    public string? KeyPrefix { get; set; }

    public long MaxFileSizeMb { get; set; } = 50;

    public long MaxThumbnailSizeMb { get; set; } = 5;

    public List<string> AllowedImageContentTypes { get; set; } =
    [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
    ];

    public List<string> AllowedVideoContentTypes { get; set; } =
    [
        "video/mp4",
        "video/webm",
        "video/quicktime",
        "video/mpeg",
    ];
}
