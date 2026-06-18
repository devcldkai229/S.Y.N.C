using Amazon.S3;
using Amazon.S3.Model;
using Libs.Seed.Configuration;
using Microsoft.Extensions.Options;

namespace Libs.Seed.Services;

public interface IS3SeedStorage
{
    Task<bool> ObjectExistsAsync(string objectKey, CancellationToken cancellationToken = default);

    Task<string> UploadAsync(Stream stream, string objectKey, string contentType, CancellationToken cancellationToken = default);

    string ResolveStoredValue(string objectKey);
}

public sealed class S3SeedStorage : IS3SeedStorage
{
    private readonly IAmazonS3 _s3;
    private readonly SeedStorageOptions _options;
    private readonly string _region;

    public S3SeedStorage(IAmazonS3 s3, IOptions<SeedStorageOptions> options)
    {
        _s3 = s3;
        _options = options.Value;
        _region = _s3.Config.RegionEndpoint?.SystemName ?? "ap-southeast-1";
    }

    public async Task<bool> ObjectExistsAsync(string objectKey, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(objectKey))
            return false;

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

    public async Task<string> UploadAsync(
        Stream stream,
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
            request.Headers.ContentLength = stream.Length - stream.Position;

        await _s3.PutObjectAsync(request, cancellationToken);
        return key;
    }

    public string ResolveStoredValue(string objectKey)
    {
        var key = objectKey.TrimStart('/');
        if (_options.PublicRead)
        {
            if (!string.IsNullOrWhiteSpace(_options.PublicBaseUrl))
                return $"{_options.PublicBaseUrl.TrimEnd('/')}/{_options.Bucket}/{key}";

            return $"https://{_options.Bucket}.s3.{_region}.amazonaws.com/{key}";
        }

        return key;
    }
}
