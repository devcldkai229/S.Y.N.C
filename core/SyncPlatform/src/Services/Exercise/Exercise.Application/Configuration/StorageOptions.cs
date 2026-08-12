using Libs.Shared.Storage;

namespace Exercise.Application.Configuration;

public class StorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = StorageBuckets.PublicAssets;
    public string KeyPrefix { get; set; } = "exercises_catalog/";
    /// <summary>
    /// CDN or gateway public base (ECS: https://cdn.&lt;domain&gt;). Key path is appended as-is
    /// (<c>{PublicBaseUrl}/{s3Key}</c>). Distinct from <see cref="MediaProxyBaseUrl"/>.
    /// </summary>
    public string? PublicBaseUrl { get; set; }
    /// <summary>Public bucket — objects are readable without presigned URLs.</summary>
    public bool PublicRead { get; set; } = true;
    /// <summary>When true and <see cref="MediaProxyBaseUrl"/> is set, prefer that URL (dev/local gateway).</summary>
    public bool UseMediaProxy { get; set; } = true;
    /// <summary>
    /// Gateway exercise media path (local). Leave empty on ECS — use <see cref="PublicBaseUrl"/> (CDN).
    /// Example: http://localhost:5057/api/v1/exercise/exercises/media/
    /// </summary>
    public string MediaProxyBaseUrl { get; set; } = "";
    public long MaxFileSizeMb { get; set; } = 50;
    public long MaxThumbnailSizeMb { get; set; } = 5;
    public List<string> AllowedImageContentTypes { get; set; } =
        ["image/jpeg", "image/png", "image/gif", "image/webp"];
    public List<string> AllowedVideoContentTypes { get; set; } =
        ["video/mp4", "video/mpeg", "video/quicktime", "video/webm"];
}
