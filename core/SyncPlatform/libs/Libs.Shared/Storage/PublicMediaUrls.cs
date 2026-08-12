namespace Libs.Shared.Storage;

/// <summary>
/// Builds public URLs for objects in <see cref="StorageBuckets.PublicAssets"/>.
/// Gateway media proxy keeps <c>{base}/{bucket}/{key}</c>; CDN / CloudFront uses <c>{base}/{key}</c>.
/// </summary>
public static class PublicMediaUrls
{
    public static string Object(string publicBaseUrl, string objectKey)
    {
        var baseUrl = publicBaseUrl.TrimEnd('/');
        var key = objectKey.TrimStart('/');
        if (IsGatewayMediaBase(baseUrl))
            return $"{baseUrl}/{StorageBuckets.PublicAssets}/{key}";
        return $"{baseUrl}/{key}";
    }

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

    /// <summary>
    /// True when <paramref name="publicBaseUrl"/> is the Gateway media proxy prefix
    /// (e.g. <c>https://api.../api/v1/media</c>), not a bare CDN origin.
    /// </summary>
    public static bool IsGatewayMediaBase(string publicBaseUrl) =>
        publicBaseUrl.TrimEnd('/').EndsWith("/api/v1/media", StringComparison.OrdinalIgnoreCase);
}
