using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Notification.Application.Clients;
using Notification.Infrastructure.Clients;
using Notification.Infrastructure.Persistence;

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

        services.AddHttpClient<IIamSmartPushClient, IamSmartPushClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["IamService:BaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["IamService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
            {
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
            }
        });

        services.AddHttpClient<IRoadmapActivityClient, RoadmapActivityClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["RoadmapService:BaseUrl"] ?? "http://localhost:5118";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["RoadmapService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
            {
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
            }
        });

        services.AddHttpClient<IDeepSeekClient, DeepSeekClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["DeepSeek:BaseUrl"] ?? "https://api.deepseek.com";
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
