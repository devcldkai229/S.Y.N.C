using Amazon.S3;
using Libs.Storage.Configuration;
using Libs.Storage.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Libs.Storage.Extensions;

public static class StorageServiceExtensions
{
    public static IServiceCollection AddS3ObjectStorage(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<ObjectStorageOptions>(configuration.GetSection(ObjectStorageOptions.SectionName));
        services.AddAWSService<IAmazonS3>();
        services.AddSingleton<S3ObjectStorage>();
        services.AddSingleton<IMediaUrlResolver, MediaUrlResolver>();
        return services;
    }
}
