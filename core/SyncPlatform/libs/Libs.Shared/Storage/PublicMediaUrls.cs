namespace Libs.Shared.Storage;

/// <summary>Builds stable gateway URLs for objects in <see cref="StorageBuckets.PublicAssets"/>.</summary>
public static class PublicMediaUrls
{
    public static string Object(string publicBaseUrl, string objectKey) =>
        $"{publicBaseUrl.TrimEnd('/')}/{StorageBuckets.PublicAssets}/{objectKey.TrimStart('/')}";

    /// <summary>Rewrites legacy bucket segments in a URL to <see cref="StorageBuckets.PublicAssets"/>.</summary>
    public static string NormalizeBucketInUrl(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return url;

        var normalized = url;
        foreach (var legacy in StorageBuckets.LegacyPublicBuckets)
        {
            normalized = normalized.Replace(
                $"/{legacy}/",
                $"/{StorageBuckets.PublicAssets}/",
                StringComparison.OrdinalIgnoreCase);
        }

        return normalized;
    }
}
