using Libs.Shared.Seed;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Minio;
using Minio.DataModel.Args;
using Social.Application.Configuration;

namespace Social.Infrastructure.Persistence.Seed;

/// <summary>
/// Uploads tiny placeholder images to MinIO so dev seed URLs resolve (public-read bucket in Development).
/// </summary>
public class MinioDevAssetSeeder
{
    private static readonly byte[] PlaceholderPng = Convert.FromBase64String(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");

    private readonly IMinioClient _minio;
    private readonly MinioOptions _options;
    private readonly ILogger<MinioDevAssetSeeder> _logger;

    public MinioDevAssetSeeder(
        IMinioClient minioClient,
        IOptions<MinioOptions> options,
        ILogger<MinioDevAssetSeeder> logger)
    {
        _minio = minioClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SeedPlaceholdersAsync(CancellationToken cancellationToken = default)
    {
        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(10));

        try
        {
            await EnsureBucketPublicReadAsync(timeoutCts.Token);

            foreach (var key in DevSeedMediaUrls.SeedObjectKeys)
            {
                timeoutCts.Token.ThrowIfCancellationRequested();

                try
                {
                    var statArgs = new StatObjectArgs()
                        .WithBucket(_options.BucketName)
                        .WithObject(key);
                    await _minio.StatObjectAsync(statArgs, timeoutCts.Token);
                }
                catch
                {
                    await using var stream = new MemoryStream(PlaceholderPng);
                    var putArgs = new PutObjectArgs()
                        .WithBucket(_options.BucketName)
                        .WithObject(key)
                        .WithStreamData(stream)
                        .WithObjectSize(PlaceholderPng.Length)
                        .WithContentType("image/png");

                    await _minio.PutObjectAsync(putArgs, timeoutCts.Token);
                    _logger.LogInformation("MinIO dev seed: uploaded placeholder {Key}", key);
                }
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning(
                "MinIO dev seed timed out after 10s (endpoint {Endpoint}). " +
                "Social API will start; ensure MinIO is running on localhost:9000.",
                _options.Endpoint);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "MinIO dev seed skipped (endpoint {Endpoint}). Social API will start without placeholder assets.",
                _options.Endpoint);
        }
    }

    private async Task EnsureBucketPublicReadAsync(CancellationToken cancellationToken)
    {
        var bucket = _options.BucketName;
        var existsArgs = new BucketExistsArgs().WithBucket(bucket);
        if (!await _minio.BucketExistsAsync(existsArgs, cancellationToken))
        {
            if (!_options.AutoCreateBucket)
            {
                _logger.LogWarning("MinIO bucket {Bucket} missing; skipping asset seed.", bucket);
                return;
            }

            await _minio.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucket), cancellationToken);
        }

        var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production";
        if (env.Equals("Production", StringComparison.OrdinalIgnoreCase))
            return;

        var policyJson = $$"""
            {
              "Version": "2012-10-17",
              "Statement": [{
                "Effect": "Allow",
                "Principal": { "AWS": ["*"] },
                "Action": ["s3:GetObject"],
                "Resource": ["arn:aws:s3:::{{bucket}}/*"]
              }]
            }
            """;

        await _minio.SetPolicyAsync(
            new SetPolicyArgs().WithBucket(bucket).WithPolicy(policyJson),
            cancellationToken);
    }
}
