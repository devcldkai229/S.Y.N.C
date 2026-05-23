using MongoDB.Driver;
using Roadmap.Domain.Models;

namespace Roadmap.Infrastructure.Persistence;

/// <summary>
/// Typed wrapper quanh IMongoDatabase — inject class này vào repositories.
/// </summary>
public sealed class RoadmapMongoContext
{
    private readonly IMongoDatabase _db;

    public RoadmapMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<PersonalizedRoadmap> PersonalizedRoadmaps
        => _db.GetCollection<PersonalizedRoadmap>("PersonalizedRoadmaps");

    public IMongoCollection<RoadmapSession> RoadmapSessions
        => _db.GetCollection<RoadmapSession>("RoadmapSessions");

    public IMongoCollection<ScheduledWorkout> ScheduledWorkouts
        => _db.GetCollection<ScheduledWorkout>("ScheduledWorkouts");

    public IMongoCollection<WorkoutExecutionLog> WorkoutExecutionLogs
        => _db.GetCollection<WorkoutExecutionLog>("WorkoutExecutionLogs");

    public IMongoCollection<UserCustomWorkout> UserCustomWorkouts
        => _db.GetCollection<UserCustomWorkout>("UserCustomWorkouts");

    public IMongoCollection<RecoveryProfile> RecoveryProfiles
        => _db.GetCollection<RecoveryProfile>("RecoveryProfiles");

    public IMongoCollection<ExerciseSetLog> ExerciseSetLogs
        => _db.GetCollection<ExerciseSetLog>("ExerciseSetLogs");
}
