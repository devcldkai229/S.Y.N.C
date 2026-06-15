using Libs.Shared.Storage;

namespace Exercise.Application.Configuration;

public class StorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = StorageBuckets.PublicAssets;
    public string KeyPrefix { get; set; } = "exercises_catalog/";
    /// <summary>Public bucket — objects are readable without presigned URLs.</summary>
    public bool PublicRead { get; set; } = true;
    /// <summary>When true, ResolveObjectUrl returns a gateway media proxy URL (avoids S3 CORS on web).</summary>
    public bool UseMediaProxy { get; set; } = true;
    /// <summary>Base URL for media proxy, e.g. http://localhost:5057/api/v1/exercise/exercises/media/</summary>
    public string MediaProxyBaseUrl { get; set; } = "http://localhost:5057/api/v1/exercise/exercises/media/";
    public long MaxFileSizeMb { get; set; } = 50;
    public long MaxThumbnailSizeMb { get; set; } = 5;
    public List<string> AllowedImageContentTypes { get; set; } =
        ["image/jpeg", "image/png", "image/gif", "image/webp"];
    public List<string> AllowedVideoContentTypes { get; set; } =
        ["video/mp4", "video/mpeg", "video/quicktime", "video/webm"];
}
