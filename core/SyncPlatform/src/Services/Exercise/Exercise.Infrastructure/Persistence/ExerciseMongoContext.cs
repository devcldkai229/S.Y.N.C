using Exercise.Domain.Models;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence;

public sealed class ExerciseMongoContext
{
    private readonly IMongoDatabase _db;

    public ExerciseMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<ExerciseCatalog> ExerciseCatalogs
        => _db.GetCollection<ExerciseCatalog>("ExerciseCatalogs");

    public IMongoCollection<ExerciseMotionAsset> ExerciseMotionAssets
        => _db.GetCollection<ExerciseMotionAsset>("ExerciseMotionAssets");

    public IMongoCollection<WorkoutTemplate> WorkoutTemplates
        => _db.GetCollection<WorkoutTemplate>("WorkoutTemplates");
}
