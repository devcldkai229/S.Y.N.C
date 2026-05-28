using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Driver;
using Roadmap.Domain.Repositories;
using Roadmap.Infrastructure.Persistence;
using Roadmap.Infrastructure.Persistence.Repositories;

namespace Roadmap.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    private static bool _conventionsRegistered;
    private static readonly Lock _lock = new();

    public static IServiceCollection AddRoadmapInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        RegisterBsonConventions();

        var connectionString = configuration.GetConnectionString("RoadmapDatabase")
            ?? throw new InvalidOperationException("Connection string 'RoadmapDatabase' is not configured.");

        var databaseName = configuration["MongoDB:RoadmapDatabaseName"] ?? "sync_roadmap";

        services.AddSingleton<IMongoClient>(_ =>
        {
            return new MongoClient(MongoClientSettings.FromConnectionString(connectionString));
        });

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<RoadmapMongoContext>();

        services.AddScoped<IUserCustomWorkoutRepository, UserCustomWorkoutRepository>();
        services.AddScoped<IRoadmapSessionRepository, RoadmapSessionRepository>();
        services.AddScoped<IScheduledWorkoutRepository, ScheduledWorkoutRepository>();
        services.AddScoped<IWorkoutExecutionLogRepository, WorkoutExecutionLogRepository>();
        services.AddScoped<IExerciseSetLogRepository, ExerciseSetLogRepository>();
        services.AddScoped<IPersonalizedRoadmapRepository, PersonalizedRoadmapRepository>();
        services.AddScoped<IRecoveryProfileRepository, RecoveryProfileRepository>();

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
                "RoadmapConventions",
                pack,
                t => t.Namespace != null &&
                     (t.Namespace.StartsWith("Roadmap") || t.Namespace.StartsWith("Libs.Shared")));

            _conventionsRegistered = true;
        }
    }
}
