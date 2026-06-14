using Amazon.Extensions.NETCore.Setup;
using Amazon.S3;
using Exercise.Application.Configuration;
using Exercise.Application.Services;
using Exercise.Infrastructure.Persistence;
using Exercise.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Conventions;
using MongoDB.Bson.Serialization.Serializers;
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

        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.SectionName));
        services.Configure<FreeExerciseDbOptions>(configuration.GetSection(FreeExerciseDbOptions.SectionName));
        services.Configure<TranslateOptions>(configuration.GetSection(TranslateOptions.SectionName));
        services.Configure<EnrichmentOptions>(configuration.GetSection(EnrichmentOptions.SectionName));

        var awsOptions = configuration.GetAWSOptions();
        services.AddDefaultAWSOptions(awsOptions);
        services.AddAWSService<IAmazonS3>();
        services.AddSingleton<IStorageService, S3StorageService>();

        var connectionString = configuration.GetConnectionString("ExerciseDatabase");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Connection string 'ExerciseDatabase' is not configured. " +
                "Set ConnectionStrings:ExerciseDatabase in appsettings.Import.json, Exercise.API/appsettings.json, " +
                "or environment variable ConnectionStrings__ExerciseDatabase.");
        }

        var databaseName = configuration["MongoDB:ExerciseDatabaseName"] ?? "sync_exercise";

        services.AddSingleton<IMongoClient>(_ =>
        {
            return new MongoClient(MongoClientSettings.FromConnectionString(connectionString));
        });

        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        services.AddSingleton<ExerciseMongoContext>();

        services.AddScoped(typeof(Exercise.Domain.Repositories.IGenericRepository<>), typeof(Exercise.Infrastructure.Persistence.Repositories.GenericRepository<>));
        services.AddScoped<Exercise.Domain.Repositories.IExerciseCatalogRepository, Exercise.Infrastructure.Persistence.Repositories.ExerciseCatalogRepository>();
        services.AddScoped<Exercise.Domain.Repositories.IExerciseMotionAssetRepository, Exercise.Infrastructure.Persistence.Repositories.ExerciseMotionAssetRepository>();
        services.AddScoped<Exercise.Domain.Repositories.IWorkoutTemplateRepository, Exercise.Infrastructure.Persistence.Repositories.WorkoutTemplateRepository>();

        return services;
    }

    private static void RegisterBsonConventions()
    {
        lock (_lock)
        {
            if (_conventionsRegistered) return;

            BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

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
