using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Nutrition.Application.Clients;
using Nutrition.Domain.Repositories;
using Nutrition.Infrastructure.Clients;
using Nutrition.Infrastructure.Persistence;
using Nutrition.Infrastructure.Persistence.Repositories;

namespace Nutrition.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddNutritionInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        var connectionString = configuration.GetConnectionString("NutritionDatabase")
            ?? throw new InvalidOperationException("Connection string 'NutritionDatabase' is not configured.");

        var databaseName = configuration["MongoDB:NutritionDatabaseName"] ?? "sync_nutrition";

        services.AddSingleton<IMongoClient>(_ =>
            new MongoClient(MongoClientSettings.FromConnectionString(connectionString)));

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<NutritionMongoContext>();

        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IFoodItemRepository, FoodItemRepository>();
        services.AddScoped<IMealLogRepository, MealLogRepository>();
        services.AddScoped<IDailyNutritionSummaryRepository, DailyNutritionSummaryRepository>();

        services.AddHttpClient<IIamBiometricClient, IamBiometricClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["IamService:BaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);

            var apiKey = config["IamService:InternalApiKey"];
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
                "NutritionConventions",
                pack,
                t => t.Namespace != null &&
                     (t.Namespace.StartsWith("Nutrition") || t.Namespace.StartsWith("Libs.Shared")));

            _conventionsRegistered = true;
        }
    }
}
