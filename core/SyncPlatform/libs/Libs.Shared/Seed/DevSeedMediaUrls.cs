namespace Libs.Shared.Seed;

/// <summary>
/// Public MinIO URLs for local dev seed data (bucket: social-assets, public-read in Development).
/// Matches <c>Minio:PublicUrl</c> + <c>Minio:BucketName</c> in Social/Exercise appsettings.
/// </summary>
public static class DevSeedMediaUrls
{
    public const string PublicBase = "http://localhost:9000";
    public const string Bucket = "social-assets";
    public const string LegacyCdnHost = "https://cdn.sync.local";

    public static string Object(string key) =>
        $"{PublicBase}/{Bucket}/{key.TrimStart('/')}";

    public static string Avatar(string fileName) => Object($"avatars/{fileName}");

    public static string Achievement(string fileName) => Object($"achievements/{fileName}");

    public static string SocialPost(string fileName) => Object($"social/{fileName}");

    /// <summary>Rewrites legacy cdn.sync.local URLs to MinIO public URLs.</summary>
    public static string MigrateLegacyUrl(string url)
    {
        if (string.IsNullOrWhiteSpace(url) || !url.Contains(LegacyCdnHost, StringComparison.OrdinalIgnoreCase))
            return url;

        return url.Replace(
            $"{LegacyCdnHost}/",
            $"{PublicBase}/{Bucket}/",
            StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>Object keys uploaded by <see cref="Social.Infrastructure.Persistence.Seed.MinioDevAssetSeeder"/>.</summary>
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
