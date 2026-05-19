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

        // IMongoClient — một instance duy nhất toàn app (thread-safe, connection-pooled)
        services.AddSingleton<IMongoClient>(_ =>
        {
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            return new MongoClient(settings);
        });

        // IMongoDatabase — derive từ client, cũng là Singleton
        services.AddSingleton<IMongoDatabase>(sp =>
            sp.GetRequiredService<IMongoClient>().GetDatabase(databaseName));

        // Typed context — inject vào repositories thay vì IMongoDatabase trực tiếp
        services.AddSingleton<ExerciseMongoContext>();

        return services;
    }

    /// <summary>
    /// Đăng ký global BSON conventions cho toàn bộ Exercise domain models.
    /// Chỉ chạy một lần — an toàn khi gọi nhiều lần nhờ lock.
    /// </summary>
    private static void RegisterBsonConventions()
    {
        lock (_lock)
        {
            if (_conventionsRegistered) return;

            var pack = new ConventionPack
            {
                // Lưu enum dưới dạng string ("Strength") thay vì integer (0)
                new EnumRepresentationConvention(BsonType.String),

                // Bỏ qua các field null khi serialize — giảm kích thước document
                new IgnoreIfNullConvention(true),

                // Bỏ qua các field có giá trị default — tối ưu storage
                new IgnoreIfDefaultConvention(false),
            };

            // Áp dụng cho tất cả class trong namespace Exercise và Libs.Shared
            ConventionRegistry.Register(
                "ExerciseConventions",
                pack,
                t => t.Namespace != null &&
                     (t.Namespace.StartsWith("Exercise") || t.Namespace.StartsWith("Libs.Shared")));

            _conventionsRegistered = true;
        }
    }
}
