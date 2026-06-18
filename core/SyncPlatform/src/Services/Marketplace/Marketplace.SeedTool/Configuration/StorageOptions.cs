namespace Marketplace.SeedTool.Configuration;

public class StorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = "sync-public-assets";

    public string KeyPrefix { get; set; } = "food_catalog/";

    /// <summary>Gateway media base, e.g. http://localhost:5057/api/v1/media. Empty = direct S3 URL.</summary>
    public string PublicBaseUrl { get; set; } = string.Empty;

    /// <summary>Public bucket — stored ImageUrls use stable gateway URLs, no presign.</summary>
    public bool PublicRead { get; set; } = true;
}
