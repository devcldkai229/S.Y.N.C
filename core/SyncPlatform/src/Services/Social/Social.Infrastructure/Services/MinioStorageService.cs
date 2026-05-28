using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Social.Application.Configuration;
using Social.Application.Services;
using Microsoft.Extensions.Options;
using Minio;
using Minio.DataModel.Args;

namespace Social.Infrastructure.Services;

public class MinioStorageService : IStorageService
{
    private readonly IMinioClient _minioClient;
    private readonly MinioOptions _options;
    private bool _bucketInitialized;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public MinioStorageService(IMinioClient minioClient, IOptions<MinioOptions> options)
    {
        _minioClient = minioClient;
        _options = options.Value;
    }

    public async Task<string> UploadFileAsync(
        Stream fileStream,
        long? objectSize,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        if (fileStream is null) throw new ArgumentNullException(nameof(fileStream));
        if (string.IsNullOrWhiteSpace(fileName)) throw new ArgumentException("File name is required.", nameof(fileName));

        await EnsureBucketExistsAsync(cancellationToken);

        var fileSize = objectSize ??
                        (fileStream.CanSeek ? fileStream.Length : throw new InvalidOperationException(
                            "Stream length is required for MinIO upload but the provided stream is not seekable."));

        var putObjectArgs = new PutObjectArgs()
            .WithBucket(_options.BucketName)
            .WithObject(fileName)
            .WithStreamData(fileStream)
            .WithObjectSize(fileSize)
            .WithContentType(contentType);

        await _minioClient.PutObjectAsync(putObjectArgs, cancellationToken);

        var baseUrl = string.IsNullOrWhiteSpace(_options.PublicUrl) ? _options.Endpoint : _options.PublicUrl;
        if (!baseUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !baseUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            baseUrl = (_options.UseSsl ? "https://" : "http://") + baseUrl;
        }

        return $"{baseUrl.TrimEnd('/')}/{_options.BucketName}/{fileName}";
    }

    private async Task EnsureBucketExistsAsync(CancellationToken cancellationToken)
    {
        if (_bucketInitialized) return;

        await _lock.WaitAsync(cancellationToken);
        try
        {
            if (_bucketInitialized) return;

            var beArgs = new BucketExistsArgs().WithBucket(_options.BucketName);
            bool found = await _minioClient.BucketExistsAsync(beArgs, cancellationToken);
            if (!found)
            {
                if (!_options.AutoCreateBucket)
                    throw new InvalidOperationException(
                        $"MinIO bucket '{_options.BucketName}' does not exist and AutoCreateBucket is false.");

                var mbArgs = new MakeBucketArgs().WithBucket(_options.BucketName);
                await _minioClient.MakeBucketAsync(mbArgs, cancellationToken);

                var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production";
                bool isProduction = env.Equals("Production", StringComparison.OrdinalIgnoreCase);

                // Not automatically set public read policy in production.
                if (!isProduction)
                {
                    var policyJson = $@"{{
                        ""Version"": ""2012-10-17"",
                        ""Statement"": [
                            {{
                                ""Effect"": ""Allow"",
                                ""Principal"": {{ ""AWS"": [""*""] }},
                                ""Action"": [""s3:GetObject""],
                                ""Resource"": [""arn:aws:s3:::{_options.BucketName}/*""]
                            }}
                        ]
                    }}";

                    var spaArgs = new SetPolicyArgs()
                        .WithBucket(_options.BucketName)
                        .WithPolicy(policyJson);
                    await _minioClient.SetPolicyAsync(spaArgs, cancellationToken);
                }
            }

            _bucketInitialized = true;
        }
        finally
        {
            _lock.Release();
        }
    }
}

