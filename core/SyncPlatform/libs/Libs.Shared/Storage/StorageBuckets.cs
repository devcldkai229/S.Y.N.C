namespace Libs.Shared.Storage;

/// <summary>Standard S3 bucket names for the platform.</summary>
public static class StorageBuckets
{
    /// <summary>Public-read assets (Exercise, Nutrition, Marketplace, Roadmap catalog media).</summary>
    public const string PublicAssets = "sync-pub-assets";

    /// <summary>Private assets (IAM profile media, Social feed/story uploads) — display via presigned URLs.</summary>
    public const string PrivateAssets = "sync-private-assets";

    /// <summary>Legacy buckets migrated into <see cref="PublicAssets"/>.</summary>
    public static readonly IReadOnlyList<string> LegacyPublicBuckets =
    [
        "social-assets",
        "sync-objs",
        "sync-public-assets",
    ];
}
