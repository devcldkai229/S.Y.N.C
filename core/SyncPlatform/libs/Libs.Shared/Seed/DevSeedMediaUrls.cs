using Libs.Shared.Storage;

namespace Libs.Shared.Seed;

/// <summary>
/// Public media URLs for local dev seed data (bucket: sync-public-assets for Social seed assets).
/// IAM / Roadmap user uploads use <see cref="StorageBuckets.PrivateAssets"/> via gateway proxy.
/// </summary>
public static class DevSeedMediaUrls
{
    public const string PublicBase = "http://localhost:5057/api/v1/media";
    public const string Bucket = StorageBuckets.PublicAssets;
    public const string LegacyCdnHost = "https://cdn.sync.local";

    public static string Object(string key) =>
        PublicMediaUrls.Object(PublicBase, key);

    public static string Avatar(string fileName) => Object($"avatars/{fileName}");

    public static string Achievement(string fileName) => Object($"achievements/{fileName}");

    public static string SocialPost(string fileName) => Object($"social/{fileName}");

    /// <summary>Rewrites legacy cdn.sync.local and old bucket names to the public-assets proxy path.</summary>
    public static string MigrateLegacyUrl(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return url;

        var migrated = url;
        if (migrated.Contains(LegacyCdnHost, StringComparison.OrdinalIgnoreCase))
        {
            migrated = migrated.Replace(
                $"{LegacyCdnHost}/",
                $"{PublicBase}/{Bucket}/",
                StringComparison.OrdinalIgnoreCase);
        }

        return PublicMediaUrls.NormalizeBucketInUrl(migrated);
    }

    /// <summary>Object keys uploaded by Social S3 dev asset seeder at startup.</summary>
    public static IReadOnlyList<string> SeedObjectKeys { get; } =
    [
        "avatars/demo-user.png",
        "avatars/admin.png",
        "avatars/partner.png",
        "achievements/first-login.png",
        "achievements/first-workout.png",
        "achievements/roadmap.png",
        "achievements/social-post.png",
        "achievements/streak-7.png",
        "achievements/streak-30.png",
        "achievements/streak-100.png",
        "achievements/perfect-3.png",
        "achievements/perfect-7.png",
        "achievements/perfect-30.png",
        "achievements/level-5.png",
        "achievements/level-10.png",
        "achievements/level-25.png",
        "social/demo-run-1.jpg",
        "social/demo-run-2.jpg",
        "social/achievement-streak7.png",
        "social/admin-team.jpg",
        "social/partner-legday.jpg",
    ];
}
