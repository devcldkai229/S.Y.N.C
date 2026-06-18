using Amazon.S3;
using Libs.Seed.Configuration;
using Libs.Seed.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Libs.Seed.Extensions;

public static class SeedServiceExtensions
{
    public static IServiceCollection AddSeedImagePipeline(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<SeedStorageOptions>(configuration.GetSection(SeedStorageOptions.SectionName));
        services.Configure<PexelsOptions>(configuration.GetSection(PexelsOptions.SectionName));
        services.AddAWSService<IAmazonS3>();
        services.AddSingleton<IS3SeedStorage, S3SeedStorage>();
        services.AddHttpClient<PexelsClient>();
        services.AddSingleton<SeedImagePipeline>();
        return services;
    }
}
