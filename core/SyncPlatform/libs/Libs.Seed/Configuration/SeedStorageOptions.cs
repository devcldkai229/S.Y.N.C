namespace Libs.Seed.Configuration;

public class SeedStorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = "sync-objs";

    public string KeyPrefix { get; set; } = string.Empty;

    /// <summary>When false, DB stores S3 object keys only (no presigned URLs).</summary>
    public bool PublicRead { get; set; }

    public string? PublicBaseUrl { get; set; }
}
