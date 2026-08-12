using Amazon.S3;
using Amazon.S3.Model;
using Exercise.Application.Configuration;
using Exercise.Application.Services;
using Libs.Shared.Storage;
using Microsoft.Extensions.Options;

namespace Exercise.Infrastructure.Services;

public class S3StorageService : IStorageService
{
    private readonly IAmazonS3 _s3;
    private readonly StorageOptions _options;
    private readonly string _region;

    public S3StorageService(IAmazonS3 s3, IOptions<StorageOptions> options)
    {
        _s3 = s3;
        _options = options.Value;
        _region = _s3.Config.RegionEndpoint?.SystemName ?? "ap-southeast-1";
    }

    public async Task<string> UploadFileAsync(
        Stream fileStream,
        string objectKey,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var request = new PutObjectRequest
        {
            BucketName = _options.Bucket,
            Key = objectKey,
            InputStream = fileStream,
            ContentType = contentType,
            AutoCloseStream = false,
        };

        if (fileStream.CanSeek)
        {
            request.Headers.ContentLength = fileStream.Length - fileStream.Position;
        }

        await _s3.PutObjectAsync(request, cancellationToken);
        return objectKey;
    }

    public async Task DeleteFileByKeyAsync(string objectKey, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(objectKey)) return;

        await _s3.DeleteObjectAsync(new DeleteObjectRequest
        {
            BucketName = _options.Bucket,
            Key = objectKey,
        }, cancellationToken);
    }

    public string ResolveObjectUrl(string objectKey)
    {
        if (string.IsNullOrWhiteSpace(objectKey)) return string.Empty;

        var key = objectKey.TrimStart('/');

        // Prod: prefer non-loopback CDN / public base (Storage__PublicBaseUrl from ECS).
        // Local defaults leave MediaProxyBaseUrl as localhost — must not win over CDN.
        if (_options.UseMediaProxy
            && !string.IsNullOrWhiteSpace(_options.MediaProxyBaseUrl)
            && !IsLoopbackBaseUrl(_options.MediaProxyBaseUrl))
        {
            return $"{_options.MediaProxyBaseUrl.TrimEnd('/')}/{key}";
        }

        if (!string.IsNullOrWhiteSpace(_options.PublicBaseUrl)
            && !IsLoopbackBaseUrl(_options.PublicBaseUrl))
        {
            return $"{_options.PublicBaseUrl.TrimEnd('/')}/{key}";
        }

        if (_options.UseMediaProxy && !string.IsNullOrWhiteSpace(_options.MediaProxyBaseUrl))
        {
            return $"{_options.MediaProxyBaseUrl.TrimEnd('/')}/{key}";
        }

        if (!string.IsNullOrWhiteSpace(_options.PublicBaseUrl))
        {
            return $"{_options.PublicBaseUrl.TrimEnd('/')}/{key}";
        }

        if (_options.PublicRead)
        {
            return $"https://{_options.Bucket}.s3.{_region}.amazonaws.com/{key}";
        }

        throw new InvalidOperationException(
            $"Storage bucket '{_options.Bucket}' is not public-read and media proxy is disabled.");
    }

    private static bool IsLoopbackBaseUrl(string baseUrl)
    {
        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var uri)) return false;
        return uri.IsLoopback
               || string.Equals(uri.Host, "localhost", StringComparison.OrdinalIgnoreCase)
               || string.Equals(uri.Host, "host.docker.internal", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<(Stream Stream, string ContentType)?> TryOpenObjectAsync(
        string objectKey,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(objectKey)) return null;

        try
        {
            var response = await _s3.GetObjectAsync(new GetObjectRequest
            {
                BucketName = _options.Bucket,
                Key = objectKey,
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
            _ => "application/octet-stream",
        };
    }

    public async Task DeleteFileAsync(string fileUrlOrKey, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fileUrlOrKey)) return;

        var key = ExtractKey(fileUrlOrKey);
        if (!string.IsNullOrWhiteSpace(key))
        {
            await DeleteFileByKeyAsync(key, cancellationToken);
        }
    }

    private string? ExtractKey(string fileUrlOrKey)
    {
        if (!fileUrlOrKey.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !fileUrlOrKey.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return fileUrlOrKey;
        }

        if (!Uri.TryCreate(fileUrlOrKey, UriKind.Absolute, out var uri)) return null;

        var path = uri.AbsolutePath.TrimStart('/');
        foreach (var bucket in new[] { _options.Bucket }.Concat(StorageBuckets.LegacyPublicBuckets))
        {
            var bucketPrefix = $"{bucket}/";
            if (path.StartsWith(bucketPrefix, StringComparison.OrdinalIgnoreCase))
                return path[bucketPrefix.Length..];
        }

        return path;
    }
}
