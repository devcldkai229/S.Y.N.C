using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Exercise.Application.Services;
using Exercise.Application.Configuration;
using Microsoft.Extensions.Options;
using Minio;
using Minio.DataModel.Args;

namespace Exercise.Infrastructure.Services;

public class MinioStorageService : IStorageService
{
    private readonly IMinioClient _minioClient;
    private readonly MinioOptions _options;
    private bool _bucketInitialized = false;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public MinioStorageService(IMinioClient minioClient, IOptions<MinioOptions> options)
    {
        _minioClient = minioClient;
        _options = options.Value;
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken = default)
    {
        await EnsureBucketExistsAsync(cancellationToken);

        var putObjectArgs = new PutObjectArgs()
            .WithBucket(_options.BucketName)
            .WithObject(fileName)
            .WithStreamData(fileStream)
            .WithObjectSize(fileStream.Length)
            .WithContentType(contentType);

        await _minioClient.PutObjectAsync(putObjectArgs, cancellationToken);

        // Construct public URL
        var baseUrl = string.IsNullOrWhiteSpace(_options.PublicUrl) ? _options.Endpoint : _options.PublicUrl;
        if (!baseUrl.StartsWith("http://") && !baseUrl.StartsWith("https://"))
        {
            var scheme = _options.UseSsl ? "https://" : "http://";
            baseUrl = scheme + baseUrl;
        }

        return $"{baseUrl.TrimEnd('/')}/{_options.BucketName}/{fileName}";
    }

    public async Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fileUrl)) return;

        string bucketSegment = $"/{_options.BucketName}/";
        int index = fileUrl.IndexOf(bucketSegment, StringComparison.OrdinalIgnoreCase);
        if (index == -1)
        {
            if (Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri))
            {
                var path = uri.AbsolutePath;
                if (path.StartsWith(bucketSegment, StringComparison.OrdinalIgnoreCase))
                {
                    var objName = path.Substring(bucketSegment.Length);
                    await RemoveObjectAsync(objName, cancellationToken);
                }
            }
            return;
        }

        var objectName = fileUrl.Substring(index + bucketSegment.Length);
        await RemoveObjectAsync(objectName, cancellationToken);
    }

    private async Task RemoveObjectAsync(string objectName, CancellationToken cancellationToken)
    {
        var removeArgs = new RemoveObjectArgs()
            .WithBucket(_options.BucketName)
            .WithObject(objectName);
        await _minioClient.RemoveObjectAsync(removeArgs, cancellationToken);
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
                if (_options.AutoCreateBucket)
                {
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
                else
                {
                    throw new InvalidOperationException($"MinIO bucket '{_options.BucketName}' does not exist and AutoCreateBucket is false.");
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
