using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Infrastructure.Options;

namespace Roadmap.Infrastructure.Persistence.Seed;

public class RoadmapDatabaseSeeder : IRoadmapDatabaseSeeder
{
    private readonly IMongoDatabase _database;
    private readonly RoadmapSeedOptions _options;
    private readonly ILogger<RoadmapDatabaseSeeder> _logger;

    public RoadmapDatabaseSeeder(
        IMongoDatabase database,
        IOptions<RoadmapSeedOptions> options,
        ILogger<RoadmapDatabaseSeeder> logger)
    {
        _database = database;
        _options = options.Value;
        _logger = logger;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            _logger.LogInformation("Roadmap database seed is disabled (Roadmap:Seed:Enabled = false).");
            return;
        }

        if (!_options.SeedDemoData)
        {
            _logger.LogInformation("Roadmap demo seed is disabled (Roadmap:Seed:SeedDemoData = false).");
            return;
        }

        var utcNow = DateTimeOffset.UtcNow;

        await SeedPersonalizedRoadmapsAsync(utcNow, cancellationToken);
        await SeedRecoveryProfilesAsync(cancellationToken);
        await SeedUserCustomWorkoutsAsync(cancellationToken);
        await SeedRoadmapSessionsAsync(utcNow, cancellationToken);
        await SeedScheduledWorkoutsAsync(utcNow, cancellationToken);
        await SeedWorkoutExecutionLogsAsync(utcNow, cancellationToken);
        await SeedExerciseSetLogsAsync(cancellationToken);

        _logger.LogInformation(
            "Roadmap seed completed. Demo user {DemoUserId} roadmap {DemoRoadmapId}.",
            RoadmapSeedUserIds.Demo,
            RoadmapSeedData.DemoRoadmapId);
    }

    private async Task SeedPersonalizedRoadmapsAsync(DateTimeOffset utcNow, CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<PersonalizedRoadmap>("PersonalizedRoadmaps");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetPersonalizedRoadmaps(utcNow),
            "personalized roadmaps",
            cancellationToken);
    }

    private async Task SeedRecoveryProfilesAsync(CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<RecoveryProfile>("RecoveryProfiles");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetRecoveryProfiles(),
            "recovery profiles",
            cancellationToken);
    }

    private async Task SeedUserCustomWorkoutsAsync(CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<UserCustomWorkout>("UserCustomWorkouts");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetUserCustomWorkouts(),
            "user custom workouts",
            cancellationToken);
    }

    private async Task SeedRoadmapSessionsAsync(DateTimeOffset utcNow, CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<RoadmapSession>("RoadmapSessions");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetRoadmapSessions(utcNow),
            "roadmap sessions",
            cancellationToken);
    }

    private async Task SeedScheduledWorkoutsAsync(DateTimeOffset utcNow, CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<ScheduledWorkout>("ScheduledWorkouts");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetScheduledWorkouts(utcNow),
            "scheduled workouts",
            cancellationToken);
    }

    private async Task SeedWorkoutExecutionLogsAsync(DateTimeOffset utcNow, CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<WorkoutExecutionLog>("WorkoutExecutionLogs");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetWorkoutExecutionLogs(utcNow),
            "workout execution logs",
            cancellationToken);
    }

    private async Task SeedExerciseSetLogsAsync(CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<ExerciseSetLog>("ExerciseSetLogs");
        await InsertMissingByIdAsync(
            collection,
            RoadmapSeedData.GetExerciseSetLogs(),
            "exercise set logs",
            cancellationToken);
    }

    private async Task InsertMissingByIdAsync<T>(
        IMongoCollection<T> collection,
        IReadOnlyList<T> seeds,
        string label,
        CancellationToken cancellationToken) where T : BaseMongoEntity
    {
        var ids = seeds.Select(s => s.Id).ToList();
        var existingIds = await collection
            .Find(Builders<T>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(cancellationToken);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        await InsertEntitiesAsync(collection, toInsert, label, cancellationToken);
    }

    private async Task InsertEntitiesAsync<T>(
        IMongoCollection<T> collection,
        IReadOnlyList<T> toInsert,
        string label,
        CancellationToken cancellationToken) where T : BaseMongoEntity
    {
        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Roadmap seed: {Label} already present.", label);
            return;
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var entity in toInsert)
        {
            entity.CreatedAt = now;
            entity.UpdatedAt = now;
        }

        await collection.InsertManyAsync(toInsert, cancellationToken: cancellationToken);
        _logger.LogInformation("Roadmap seed: inserted {Count} {Label}.", toInsert.Count, label);
    }
}
