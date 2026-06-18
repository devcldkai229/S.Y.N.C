using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Libs.Shared.Storage;
using Libs.Storage.Configuration;
using Microsoft.Extensions.Options;

namespace Libs.Storage.Services;

public sealed class S3ObjectStorage
{
    private static readonly IReadOnlyDictionary<string, string> KnownBucketRegions =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            [StorageBuckets.PublicAssets] = "us-east-1",
            ["sync-objs"] = "ap-southeast-1",
        };

    private readonly IAmazonS3 _s3;
    private readonly ObjectStorageOptions _options;

    public S3ObjectStorage(IAmazonS3 s3, IOptions<ObjectStorageOptions> options)
    {
        _s3 = s3;
        _options = options.Value;
    }

    public ObjectStorageOptions Options => _options;

    public async Task<string> UploadAsync(
        Stream stream,
        long objectSize,
        string objectKey,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var key = objectKey.TrimStart('/');
        var request = new PutObjectRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            InputStream = stream,
            ContentType = contentType,
            AutoCloseStream = false,
        };

        if (stream.CanSeek)
            request.Headers.ContentLength = objectSize;

        await _s3.PutObjectAsync(request, cancellationToken);
        return ResolveUrl(key);
    }

    public string ResolveUrl(string objectKey) =>
        $"{_options.PublicBaseUrl.TrimEnd('/')}/{_options.Bucket}/{objectKey.TrimStart('/')}";

    public async Task<(Stream Stream, string ContentType)?> TryGetObjectAsync(
        string bucket,
        string objectKey,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(bucket) || string.IsNullOrWhiteSpace(objectKey))
            return null;

        var client = ResolveClientForBucket(bucket);
        var disposeClient = !ReferenceEquals(client, _s3);
        try
        {
            var response = await client.GetObjectAsync(new GetObjectRequest
            {
                BucketName = bucket,
                Key = objectKey.TrimStart('/'),
            }, cancellationToken);

            var contentType = string.IsNullOrWhiteSpace(response.Headers.ContentType)
                ? GuessContentType(objectKey)
                : response.Headers.ContentType;

            return (response.ResponseStream, contentType);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
        finally
        {
            if (disposeClient)
                client.Dispose();
        }
    }

    /// <summary>Path format: {bucket}/{objectKey...}</summary>
    public Task<(Stream Stream, string ContentType)?> TryGetObjectByPathAsync(
        string bucketAndKey,
        CancellationToken cancellationToken = default)
    {
        var trimmed = bucketAndKey.TrimStart('/');
        var slash = trimmed.IndexOf('/');
        if (slash <= 0)
            return Task.FromResult<(Stream, string ContentType)?>(null);

        var bucket = trimmed[..slash];
        var key = trimmed[(slash + 1)..];
        return TryGetObjectAsync(bucket, key, cancellationToken);
    }

    public async Task<bool> ObjectExistsAsync(string objectKey, CancellationToken cancellationToken = default)
    {
        try
        {
            await _s3.GetObjectMetadataAsync(new GetObjectMetadataRequest
            {
                BucketName = _options.Bucket,
                Key = objectKey.TrimStart('/'),
            }, cancellationToken);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
    }

    private IAmazonS3 ResolveClientForBucket(string bucket)
    {
        if (!KnownBucketRegions.TryGetValue(bucket, out var region))
            return _s3;

        var current = _s3.Config.RegionEndpoint?.SystemName;
        if (string.Equals(current, region, StringComparison.OrdinalIgnoreCase))
            return _s3;

        return new AmazonS3Client(RegionEndpoint.GetBySystemName(region));
    }

    private static string GuessContentType(string objectKey)
    {
        var ext = Path.GetExtension(objectKey).ToLowerInvariant();
        return ext switch
        {
            ".webp" => "image/webp",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".gif" => "image/gif",
            ".mp4" => "video/mp4",
            ".webm" => "video/webm",
            _ => "application/octet-stream",
        };
    }
}
