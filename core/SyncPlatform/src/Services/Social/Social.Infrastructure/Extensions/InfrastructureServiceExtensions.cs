using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Social.Domain.Repositories;
using Social.Infrastructure.Options;
using Social.Infrastructure.Persistence;
using Social.Infrastructure.Persistence.Repositories;
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

        var connectionString = configuration.GetConnectionString("SocialDatabase")
            ?? throw new InvalidOperationException("Connection string 'SocialDatabase' is not configured.");

        var databaseName = configuration["MongoDB:SocialDatabaseName"] ?? "sync_social";

        services.AddSingleton<IMongoClient>(_ =>
        {
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            return new MongoClient(settings);
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

        services.Configure<SocialSeedOptions>(configuration.GetSection(SocialSeedOptions.SectionName));
        services.AddScoped<ISocialDatabaseSeeder, SocialDatabaseSeeder>();

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
