using Amazon.LocationService;
using Libs.Storage.Extensions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Social.Application.Clients;
using Social.Domain.Repositories;
using Social.Application.Services;
using Social.Infrastructure.Clients;
using Social.Infrastructure.Options;
using Social.Infrastructure.Persistence;
using Social.Infrastructure.Persistence.Repositories;
using Social.Infrastructure.Services;
using Social.Infrastructure.Persistence.Seed;

namespace Social.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddSocialInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        services.AddS3ObjectStorage(configuration);
        services.Configure<AwsLocationOptions>(configuration.GetSection(AwsLocationOptions.SectionName));

        var awsLocation = configuration.GetSection(AwsLocationOptions.SectionName).Get<AwsLocationOptions>()
            ?? new AwsLocationOptions();
        if (awsLocation.IsConfigured)
        {
            services.AddSingleton<IAmazonLocationService>(_ =>
                AwsLocationChallengeRouteCalculator.CreateClient(awsLocation));
            services.AddScoped<IChallengeRouteCalculator, AwsLocationChallengeRouteCalculator>();
        }
        else
        {
            services.AddScoped<IChallengeRouteCalculator, HaversineChallengeRouteCalculator>();
        }

        services.AddSingleton<IStorageService, S3StorageService>();

        var connectionString = configuration.GetConnectionString("SocialDatabase")
            ?? throw new InvalidOperationException("Connection string 'SocialDatabase' is not configured.");

        var databaseName = configuration["MongoDB:SocialDatabaseName"] ?? "sync_social";

        services.AddSingleton<IMongoClient>(_ =>
        {
            return new MongoClient(MongoClientSettings.FromConnectionString(connectionString));
        });

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<SocialMongoContext>();

        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IPostRepository, PostRepository>();
        services.AddScoped<IInteractionRepository, InteractionRepository>();
        services.AddScoped<ICommentRepository, CommentRepository>();
        services.AddScoped<IPostEngagementRepository, PostEngagementRepository>();
        services.AddScoped<ICommunityChallengeRepository, CommunityChallengeRepository>();
        services.AddScoped<IChallengeParticipantRepository, ChallengeParticipantRepository>();
        services.AddScoped<IChallengeParticipationRepository, ChallengeParticipationRepository>();
        services.AddScoped<IUserFollowRepository, UserFollowRepository>();
        services.AddScoped<IUserSocialSettingsRepository, UserSocialSettingsRepository>();
        services.AddScoped<IStoryRepository, StoryRepository>();
        services.AddScoped<IStoryInteractionRepository, StoryInteractionRepository>();
        services.AddScoped<IStoryViewRepository, StoryViewRepository>();
        services.AddScoped<IBlogRepository, BlogRepository>();
        services.AddScoped<IBlogInteractionRepository, BlogInteractionRepository>();

        services.Configure<SocialSeedOptions>(configuration.GetSection(SocialSeedOptions.SectionName));
        services.AddScoped<ISocialDatabaseSeeder, SocialDatabaseSeeder>();
        services.AddScoped<S3DevAssetSeeder>();

        // Inter-service: IAM gamification (grant XP after social events)
        services.AddHttpClient<IIamGamificationClient, IamGamificationClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["IamService:BaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);

            var apiKey = config["IamService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IIamUserSearchClient, IamUserSearchClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["IamService:BaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["IamService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<ISocialNotificationClient, SocialNotificationClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["NotificationService:BaseUrl"] ?? "http://localhost:5106";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);

            var apiKey = config["NotificationService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        return services;
    }

    private static void RegisterBsonConventions()
    {
        lock (_lock)
        {
            if (_conventionsRegistered) return;

            var pack = new ConventionPack
            {
                new EnumRepresentationConvention(BsonType.String),
                new IgnoreIfNullConvention(true),
            };

            ConventionRegistry.Register(
                "SocialConventions",
                pack,
                t => t.Namespace != null && t.Namespace.StartsWith("Social"));

            _conventionsRegistered = true;
        }
    }
}
