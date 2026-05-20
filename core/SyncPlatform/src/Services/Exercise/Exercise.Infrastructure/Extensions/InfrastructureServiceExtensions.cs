using Exercise.Infrastructure.Persistence;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddExerciseInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        var connectionString = configuration.GetConnectionString("ExerciseDatabase")
            ?? throw new InvalidOperationException("Connection string 'ExerciseDatabase' is not configured.");

        var databaseName = configuration["MongoDB:ExerciseDatabaseName"] ?? "sync_exercise";

        services.AddSingleton<IMongoClient>(_ =>
        {
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            return new MongoClient(settings);
        });

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<ExerciseMongoContext>();

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

                new IgnoreIfDefaultConvention(false),
            };

            ConventionRegistry.Register(
                "ExerciseConventions",
                pack,
                t => t.Namespace != null &&
                     (t.Namespace.StartsWith("Exercise") || t.Namespace.StartsWith("Libs.Shared")));

            _conventionsRegistered = true;
        }
    }
}
