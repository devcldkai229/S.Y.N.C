using Amazon.S3;
using Amazon.S3.Model;
using Libs.Shared.Storage;
using Libs.Storage.Configuration;
using Microsoft.Extensions.Options;

namespace Libs.Storage.Services;

public sealed class MediaUrlResolver : IMediaUrlResolver
{
    private const string MediaPathMarker = "/api/v1/media/";

    private readonly IAmazonS3 _s3;
    private readonly ObjectStorageOptions _options;

    public MediaUrlResolver(IAmazonS3 s3, IOptions<ObjectStorageOptions> options)
    {
        _s3 = s3;
        _options = options.Value;
    }

    public string? ResolveForDisplay(string? storedValue)
    {
        if (string.IsNullOrWhiteSpace(storedValue))
            return null;

        if (storedValue.StartsWith("randomavatar:", StringComparison.OrdinalIgnoreCase))
            return storedValue;

        if (TryParseBucketAndKey(storedValue, out var bucket, out var key))
        {
            if (IsPublicBucket(bucket))
                return ResolvePublicBucketUrl(key);

            return GetPresignedDownloadUrl(bucket, key);
        }

        if (!storedValue.Contains("://", StringComparison.Ordinal))
            return GetPresignedDownloadUrl(_options.Bucket, storedValue.TrimStart('/'));

        return storedValue;
    }

    public string? NormalizeForStorage(string? urlOrKey)
    {
        if (string.IsNullOrWhiteSpace(urlOrKey))
            return null;

        if (urlOrKey.StartsWith("randomavatar:", StringComparison.OrdinalIgnoreCase))
            return urlOrKey;

        if (TryParseBucketAndKey(urlOrKey, out var bucket, out var key))
        {
            if (string.Equals(bucket, _options.Bucket, StringComparison.OrdinalIgnoreCase))
                return key;

            return $"{bucket}/{key}";
        }

        if (!urlOrKey.Contains("://", StringComparison.Ordinal))
            return urlOrKey.TrimStart('/');

        return urlOrKey;
    }

    public string ResolveAfterUpload(string objectKey) =>
        ResolveForDisplay(objectKey) ?? objectKey;

    private string GetPresignedDownloadUrl(string bucket, string key)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = bucket,
            Key = key.TrimStart('/'),
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddHours(1),
        };

        var client = S3BucketClientResolver.Resolve(_s3, bucket);
        var disposeClient = !ReferenceEquals(client, _s3);
        try
        {
            return client.GetPreSignedURL(request);
        }
        finally
        {
            if (disposeClient)
                client.Dispose();
        }
    }

    private string ResolvePublicBucketUrl(string key)
    {
        if (!string.IsNullOrWhiteSpace(_options.PublicBaseUrl))
            return PublicMediaUrls.Object(_options.PublicBaseUrl, key);

        var bucket = StorageBuckets.PublicAssets;
        var region = S3BucketClientResolver.DefaultRegion(_s3);
        return $"https://{bucket}.s3.{region}.amazonaws.com/{key.TrimStart('/')}";
    }

    private static bool IsPublicBucket(string bucket) =>
        string.Equals(bucket, StorageBuckets.PublicAssets, StringComparison.OrdinalIgnoreCase);

    private static bool TryParseBucketAndKey(string value, out string bucket, out string key)
    {
        bucket = string.Empty;
        key = string.Empty;

        var trimmed = value.Trim();
        var path = trimmed;

        var markerIndex = trimmed.IndexOf(MediaPathMarker, StringComparison.OrdinalIgnoreCase);
        if (markerIndex >= 0)
            path = trimmed[(markerIndex + MediaPathMarker.Length)..];

        var queryIndex = path.IndexOf('?', StringComparison.Ordinal);
        if (queryIndex >= 0)
            path = path[..queryIndex];

        // CDN / CloudFront: https://cdn.synctis.in[/sync-pub-assets]/key
        if (TryParseCdnUrl(trimmed, out bucket, out key))
            return true;

        if (path.Contains(".amazonaws.com/", StringComparison.OrdinalIgnoreCase))
        {
            var uri = new Uri(trimmed.Split('?')[0]);
            var host = uri.Host;
            var objectPath = uri.AbsolutePath.TrimStart('/');

            if (host.StartsWith("s3.", StringComparison.OrdinalIgnoreCase)
                || host.StartsWith("s3-", StringComparison.OrdinalIgnoreCase))
            {
                var slash = objectPath.IndexOf('/');
                if (slash > 0)
                {
                    bucket = objectPath[..slash];
                    key = objectPath[(slash + 1)..];
                    return !string.IsNullOrWhiteSpace(bucket) && !string.IsNullOrWhiteSpace(key);
                }
            }

            var bucketEnd = host.IndexOf(".s3", StringComparison.OrdinalIgnoreCase);
            if (bucketEnd > 0)
            {
                bucket = host[..bucketEnd];
                key = objectPath;
                return !string.IsNullOrWhiteSpace(bucket) && !string.IsNullOrWhiteSpace(key);
            }
        }

        if (markerIndex >= 0 || (!trimmed.Contains("://", StringComparison.Ordinal) && path.Contains('/')))
        {
            var slash = path.IndexOf('/');
            if (slash <= 0)
                return false;

            var candidate = path[..slash];

            // When the path came from the media proxy marker (/api/v1/media/<bucket>/<key>),
            // the first segment IS the bucket. Otherwise (e.g. "profiles/abc.jpg" stored as a
            // bare S3 key) the first segment is NOT a bucket — treat the whole path as a key.
            if (markerIndex < 0 && !LooksLikeBucketName(candidate))
                return false;

            bucket = candidate;
            key = path[(slash + 1)..];
            return !string.IsNullOrWhiteSpace(bucket) && !string.IsNullOrWhiteSpace(key);
        }

        return false;
    }

    private static bool TryParseCdnUrl(string value, out string bucket, out string key)
    {
        bucket = string.Empty;
        key = string.Empty;

        if (!Uri.TryCreate(value.Split('?')[0], UriKind.Absolute, out var uri))
            return false;

        var host = uri.Host;
        if (!host.Equals("cdn.synctis.in", StringComparison.OrdinalIgnoreCase)
            && !host.EndsWith(".cloudfront.net", StringComparison.OrdinalIgnoreCase)
            && !host.Equals("cdn.sync.local", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var objectPath = uri.AbsolutePath.TrimStart('/');
        if (string.IsNullOrWhiteSpace(objectPath))
            return false;

        // Legacy mistaken shape: /sync-pub-assets/<key> or /legacy-bucket/<key>
        var slash = objectPath.IndexOf('/');
        if (slash > 0)
        {
            var first = objectPath[..slash];
            if (LooksLikeBucketName(first)
                || string.Equals(first, StorageBuckets.PublicAssets, StringComparison.OrdinalIgnoreCase)
                || StorageBuckets.LegacyPublicBuckets.Any(b =>
                    string.Equals(b, first, StringComparison.OrdinalIgnoreCase)))
            {
                bucket = StorageBuckets.PublicAssets;
                key = objectPath[(slash + 1)..];
                return !string.IsNullOrWhiteSpace(key);
            }
        }

        // Correct CDN shape: /prod/... or /profiles/...
        bucket = StorageBuckets.PublicAssets;
        key = objectPath;
        return true;
    }

    /// <summary>
    /// Heuristic: real S3 bucket names in this project contain "sync-".
    /// Folder prefixes like "profiles", "stories", "exercises_catalog" do not.
    /// </summary>
    private static bool LooksLikeBucketName(string segment) =>
        segment.Contains("sync-", StringComparison.OrdinalIgnoreCase);
}
