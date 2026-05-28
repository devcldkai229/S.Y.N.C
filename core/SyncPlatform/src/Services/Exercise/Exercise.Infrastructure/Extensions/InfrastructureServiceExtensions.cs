using Exercise.Application.Services;
using Exercise.Application.Configuration;
using Exercise.Infrastructure.Persistence;
using Exercise.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Minio;
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

        services.Configure<MinioOptions>(configuration.GetSection(MinioOptions.SectionName));

        services.AddSingleton<IMinioClient>(sp =>
        {
            var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<MinioOptions>>().Value;
            return new MinioClient()
                .WithEndpoint(options.Endpoint)
                .WithCredentials(options.AccessKey, options.SecretKey)
                .WithSSL(options.UseSsl)
                .Build();
        });

        services.AddSingleton<IStorageService, MinioStorageService>();

        var connectionString = configuration.GetConnectionString("ExerciseDatabase")
            ?? throw new InvalidOperationException("Connection string 'ExerciseDatabase' is not configured.");

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
