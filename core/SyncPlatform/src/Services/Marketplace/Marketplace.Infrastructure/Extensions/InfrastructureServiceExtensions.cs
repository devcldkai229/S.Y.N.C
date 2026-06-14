using Marketplace.Application.Clients;
using Marketplace.Domain.Repositories;
using Marketplace.Infrastructure.Clients;
using Marketplace.Infrastructure.Persistence;
using Marketplace.Infrastructure.Persistence.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddMarketplaceInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        var connectionString = configuration.GetConnectionString("MarketplaceDatabase")
            ?? throw new InvalidOperationException("Connection string 'MarketplaceDatabase' is not configured.");

        var databaseName = configuration["MongoDB:MarketplaceDatabaseName"] ?? "sync_marketplace";

        services.AddSingleton<IMongoClient>(_ =>
            new MongoClient(MongoClientSettings.FromConnectionString(connectionString)));

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<MarketplaceMongoContext>();

        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IPartnerRepository, PartnerRepository>();
        services.AddScoped<IFoodMenuItemRepository, FoodMenuItemRepository>();
        services.AddScoped<IAffiliateProductRepository, AffiliateProductRepository>();
        services.AddScoped<IReviewRepository, ReviewRepository>();
        services.AddScoped<IAffiliateClickEventRepository, AffiliateClickEventRepository>();
        services.AddScoped<Marketplace.Application.Services.IInternalMarketplaceService, Marketplace.Infrastructure.Services.InternalMarketplaceService>();

        services.AddHttpClient<IIamUserClient, IamUserClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["IamService:BaseUrl"] ?? "http://localhost:5288");
            client.Timeout = TimeSpan.FromSeconds(5);
            var apiKey = config["IamService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IOrderVerificationClient, OrderVerificationClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["OrderService:BaseUrl"] ?? "http://localhost:5123");
            client.Timeout = TimeSpan.FromSeconds(5);
            var apiKey = config["OrderService:InternalApiKey"];
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
                "MarketplaceConventions",
                pack,
                t => t.Namespace != null &&
                     (t.Namespace.StartsWith("Marketplace") || t.Namespace.StartsWith("Libs.Shared")));

            _conventionsRegistered = true;
        }
    }
}
