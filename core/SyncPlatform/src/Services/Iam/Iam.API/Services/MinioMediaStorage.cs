using Iam.API.Configuration;
using Microsoft.Extensions.Options;
using Minio;
using Minio.DataModel.Args;

namespace Iam.API.Services;

public interface IMediaStorage
{
    Task<string> UploadAsync(Stream stream, long size, string objectName, string contentType, CancellationToken cancellationToken);
}

public sealed class MinioMediaStorage : IMediaStorage
{
    private readonly IMinioClient _client;
    private readonly MinioOptions _options;
    private readonly SemaphoreSlim _lock = new(1, 1);
    private bool _bucketReady;

    public MinioMediaStorage(IMinioClient client, IOptions<MinioOptions> options)
    {
        _client = client;
        _options = options.Value;
    }

    public async Task<string> UploadAsync(
        Stream stream,
        long size,
        string objectName,
        string contentType,
        CancellationToken cancellationToken)
    {
        await EnsureBucketAsync(cancellationToken);

        await _client.PutObjectAsync(
            new PutObjectArgs()
                .WithBucket(_options.BucketName)
                .WithObject(objectName)
                .WithStreamData(stream)
                .WithObjectSize(size)
                .WithContentType(contentType),
            cancellationToken);

        var baseUrl = string.IsNullOrWhiteSpace(_options.PublicUrl) ? _options.Endpoint : _options.PublicUrl;
        if (!baseUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !baseUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            baseUrl = (_options.UseSsl ? "https://" : "http://") + baseUrl;
        }

        return $"{baseUrl.TrimEnd('/')}/{_options.BucketName}/{objectName}";
    }

    private async Task EnsureBucketAsync(CancellationToken cancellationToken)
    {
        if (_bucketReady || !_options.AutoCreateBucket) return;

        await _lock.WaitAsync(cancellationToken);
        try
        {
            if (_bucketReady) return;
            var exists = await _client.BucketExistsAsync(
                new BucketExistsArgs().WithBucket(_options.BucketName),
                cancellationToken);
            if (!exists)
            {
                await _client.MakeBucketAsync(
                    new MakeBucketArgs().WithBucket(_options.BucketName),
                    cancellationToken);
            }

            _bucketReady = true;
        }
        finally
        {
            _lock.Release();
        }
    }
}
