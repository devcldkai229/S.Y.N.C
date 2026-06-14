using Amazon.S3;
using Amazon.S3.Model;
using Marketplace.SeedTool.Configuration;
using Microsoft.Extensions.Options;

namespace Marketplace.SeedTool.Services;

public sealed class S3StorageService : IStorageService
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

    public async Task<bool> ObjectExistsAsync(string objectKey, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(objectKey))
            return false;

        try
        {
            await _s3.GetObjectMetadataAsync(new GetObjectMetadataRequest
            {
                BucketName = _options.Bucket,
                Key = objectKey,
            }, cancellationToken);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
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
            request.Headers.ContentLength = fileStream.Length - fileStream.Position;

        await _s3.PutObjectAsync(request, cancellationToken);
        return objectKey;
    }

    public string ResolveObjectUrl(string objectKey)
    {
        if (string.IsNullOrWhiteSpace(objectKey))
            return string.Empty;

        if (_options.PublicRead)
            return $"https://{_options.Bucket}.s3.{_region}.amazonaws.com/{objectKey}";

        return _s3.GetPreSignedURL(new GetPreSignedUrlRequest
        {
            BucketName = _options.Bucket,
            Key = objectKey,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddMinutes(_options.PresignedUrlExpiryMinutes),
        });
    }
}
