namespace Marketplace.SeedTool.Configuration;

public class StorageOptions
{
    public const string SectionName = "Storage";

    public string Bucket { get; set; } = "sync-objs";

    public string KeyPrefix { get; set; } = "food_catalog/";

    public bool PublicRead { get; set; }

    public int PresignedUrlExpiryMinutes { get; set; } = 60;
}
