using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Notification.Application.Clients;
using Notification.Application.Options;
using Notification.Application.Services.SmartPush;
using Notification.Infrastructure.Clients;
using Notification.Infrastructure.Persistence;
using Notification.Infrastructure.Persistence.Repositories;

namespace Notification.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddNotificationInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        var connectionString = configuration.GetConnectionString("NotificationDatabase")
            ?? throw new InvalidOperationException("Connection string 'NotificationDatabase' is not configured.");

        var databaseName = configuration["MongoDB:NotificationDatabaseName"] ?? "sync_notification";

        services.AddSingleton<IMongoClient>(_ =>
        {
            return new MongoClient(MongoClientSettings.FromConnectionString(connectionString));
        });

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<NotificationMongoContext>();

        services.AddScoped(typeof(Notification.Domain.Repositories.IGenericRepository<>), typeof(Notification.Infrastructure.Persistence.Repositories.GenericRepository<>));
        services.AddScoped<Notification.Domain.Repositories.INotificationMessageRepository, Notification.Infrastructure.Persistence.Repositories.NotificationMessageRepository>();
        services.AddScoped<Notification.Domain.Repositories.INotificationTemplateRepository, Notification.Infrastructure.Persistence.Repositories.NotificationTemplateRepository>();

        // Smart Push Postgres (schedule + log)
        var smartPushCs = configuration.GetConnectionString("SmartPushDatabase")
            ?? throw new InvalidOperationException("Connection string 'SmartPushDatabase' is not configured.");

        services.AddDbContext<SmartPushDbContext>(options =>
            options
                .UseNpgsql(smartPushCs, npgsql =>
                {
                    npgsql.MigrationsHistoryTable("__ef_migrations_history", "smart_push");
                    npgsql.EnableRetryOnFailure(maxRetryCount: 5);
                })
                .UseSnakeCaseNamingConvention());

        services.AddScoped<ISmartPushScheduleRepository, SmartPushScheduleRepository>();

        services.Configure<SmartPushOptions>(configuration.GetSection(SmartPushOptions.SectionName));
        services.Configure<OpenAiOptions>(configuration.GetSection(OpenAiOptions.SectionName));

        services.AddHttpClient<IIamSmartPushClient, IamSmartPushClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["IamService:BaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["IamService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IRoadmapActivityClient, RoadmapActivityClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["RoadmapService:BaseUrl"] ?? "http://localhost:5118";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["RoadmapService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<INutritionActivityClient, NutritionActivityClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["NutritionService:BaseUrl"] ?? "http://localhost:5122";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["NutritionService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IOpenAiClient, OpenAiClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["OpenAI:BaseUrl"] ?? "https://api.openai.com/v1";
            if (!baseUrl.EndsWith('/'))
                baseUrl += "/";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(30);
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
                "NotificationConventions",
                pack,
                t => t.Namespace != null &&
                     t.Namespace.StartsWith("Notification"));

            _conventionsRegistered = true;
        }
    }
}
