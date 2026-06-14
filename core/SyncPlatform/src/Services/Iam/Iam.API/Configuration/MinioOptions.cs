namespace Iam.API.Configuration;

public class MinioOptions
{
    public const string SectionName = "Minio";

    public string Endpoint { get; set; } = string.Empty;
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string BucketName { get; set; } = "social-assets";
    public bool UseSsl { get; set; }
    public string PublicUrl { get; set; } = string.Empty;
    public bool AutoCreateBucket { get; set; } = true;
    public long MaxFileSizeMb { get; set; } = 10;

    public List<string> AllowedImageContentTypes { get; set; } =
    [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp"
    ];
}
