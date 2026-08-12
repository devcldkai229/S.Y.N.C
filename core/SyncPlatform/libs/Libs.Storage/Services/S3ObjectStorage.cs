using Amazon.S3;
using Amazon.S3.Model;
using Libs.Storage.Configuration;
using Microsoft.Extensions.Options;

namespace Libs.Storage.Services;

public sealed class S3ObjectStorage
{
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
        var key = ApplyKeyPrefix(objectKey);
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

        // Bucket may live in a different region than AWS:Region.
        var client = S3BucketClientResolver.Resolve(_s3, _options.Bucket);
        var disposeClient = !ReferenceEquals(client, _s3);
        try
        {
            await client.PutObjectAsync(request, cancellationToken);
        }
        finally
        {
            if (disposeClient)
                client.Dispose();
        }

        return ResolveUrl(key);
    }

    /// <summary>
    /// Gateway media proxy: {PublicBaseUrl}/{bucket}/{key}.
    /// CDN / CloudFront: {PublicBaseUrl}/{key} (origin maps path → object key; no bucket segment).
    /// </summary>
    public string ResolveUrl(string objectKey)
    {
        var baseUrl = _options.PublicBaseUrl.TrimEnd('/');
        var key = objectKey.TrimStart('/');
        if (IsGatewayMediaBase(baseUrl))
            return $"{baseUrl}/{_options.Bucket}/{key}";
        return $"{baseUrl}/{key}";
    }

    private static bool IsGatewayMediaBase(string publicBaseUrl) =>
        publicBaseUrl.EndsWith("/api/v1/media", StringComparison.OrdinalIgnoreCase);
    public async Task<(Stream Stream, string ContentType)?> TryGetObjectAsync(
        string bucket,
        string objectKey,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(bucket) || string.IsNullOrWhiteSpace(objectKey))
            return null;

        var client = S3BucketClientResolver.Resolve(_s3, bucket);
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
        var key = ApplyKeyPrefix(objectKey);
        var client = S3BucketClientResolver.Resolve(_s3, _options.Bucket);
        var disposeClient = !ReferenceEquals(client, _s3);
        try
        {
            await client.GetObjectMetadataAsync(new GetObjectMetadataRequest
            {
                BucketName = _options.Bucket,
                Key = key,
            }, cancellationToken);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
        finally
        {
            if (disposeClient)
                client.Dispose();
        }
    }

    private string ApplyKeyPrefix(string objectKey)
    {
        var key = objectKey.TrimStart('/');
        if (string.IsNullOrWhiteSpace(_options.KeyPrefix))
            return key;

        var prefix = _options.KeyPrefix.Trim().Trim('/') + "/";
        if (!key.StartsWith(prefix, StringComparison.Ordinal))
            key = prefix + key;
        return key;
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
