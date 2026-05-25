using System.Collections.Generic;

namespace Exercise.Application.Configuration;

public class MinioOptions
{
    public const string SectionName = "Minio";

    public string Endpoint { get; set; } = string.Empty;
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string BucketName { get; set; } = "exercise-assets";
    public bool UseSsl { get; set; } = false;
    public string PublicUrl { get; set; } = string.Empty;
    public bool AutoCreateBucket { get; set; } = true;
    public long MaxFileSizeMb { get; set; } = 50;
    public long MaxThumbnailSizeMb { get; set; } = 5;
    public List<string> AllowedImageContentTypes { get; set; } = new()
    {
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp"
    };
    public List<string> AllowedVideoContentTypes { get; set; } = new()
    {
        "video/mp4",
        "video/mpeg",
        "video/quicktime",
        "video/webm"
    };
}
