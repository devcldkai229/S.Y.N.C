using Amazon;
using Amazon.S3;
using Libs.Shared.Storage;

namespace Libs.Storage.Services;

/// <summary>Resolves an <see cref="IAmazonS3"/> client for the bucket's region.</summary>
internal static class S3BucketClientResolver
{
    private static readonly IReadOnlyDictionary<string, string> KnownBucketRegions =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            [StorageBuckets.PublicAssets] = "ap-southeast-1",
            [StorageBuckets.PrivateAssets] = "ap-southeast-1",
            ["sync-objs"] = "ap-southeast-1",
            ["sync-public-assets"] = "ap-southeast-1",
        };

    /// <summary>
    /// Returns <paramref name="defaultClient"/> when its region matches the bucket,
    /// otherwise a new client for the known bucket region (caller must dispose if not default).
    /// </summary>
    public static IAmazonS3 Resolve(IAmazonS3 defaultClient, string bucket)
    {
        if (!KnownBucketRegions.TryGetValue(bucket, out var region))
            return defaultClient;

        var current = defaultClient.Config.RegionEndpoint?.SystemName;
        if (string.Equals(current, region, StringComparison.OrdinalIgnoreCase))
            return defaultClient;

        return new AmazonS3Client(RegionEndpoint.GetBySystemName(region));
    }

    public static string DefaultRegion(IAmazonS3 client) =>
        client.Config.RegionEndpoint?.SystemName ?? "ap-southeast-1";
}
