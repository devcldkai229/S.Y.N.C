namespace Libs.Shared.Storage;

/// <summary>Standard S3 bucket names for the platform.</summary>
public static class StorageBuckets
{
    /// <summary>Public-read assets (social, marketplace food, exercise media, avatars, …).</summary>
    public const string PublicAssets = "sync-public-assets";

    /// <summary>Private assets (future: documents, exports, …).</summary>
    public const string PrivateAssets = "sync-private-assets";

    /// <summary>Legacy buckets migrated into <see cref="PublicAssets"/>.</summary>
    public static readonly IReadOnlyList<string> LegacyPublicBuckets =
    [
        "social-assets",
        "sync-objs",
    ];
}
