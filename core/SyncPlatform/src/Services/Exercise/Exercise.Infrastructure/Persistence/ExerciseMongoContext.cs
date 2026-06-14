using Exercise.Domain.Models;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence;

public sealed class ExerciseMongoContext
{
    private readonly IMongoDatabase _db;

    public ExerciseMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<ExerciseCatalog> ExerciseCatalogs
        => _db.GetCollection<ExerciseCatalog>("ExerciseCatalog");

    public IMongoCollection<ExerciseMotionAsset> ExerciseMotionAssets
        => _db.GetCollection<ExerciseMotionAsset>("ExerciseMotionAsset");

    public IMongoCollection<WorkoutTemplate> WorkoutTemplates
        => _db.GetCollection<WorkoutTemplate>("WorkoutTemplates");
}
