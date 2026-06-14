using Exercise.Domain.Models;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence;

public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigureExerciseCatalogIndexesAsync(database);
        await ConfigureExerciseMotionAssetIndexesAsync(database);
        await ConfigureWorkoutTemplateIndexesAsync(database);
    }

    private static async Task ConfigureExerciseCatalogIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<ExerciseCatalog>("ExerciseCatalog");
        var ix = Builders<ExerciseCatalog>.IndexKeys;

        var codeIndex = new CreateIndexModel<ExerciseCatalog>(
            ix.Ascending(x => x.ExerciseCode),
            new CreateIndexOptions { Unique = true, Name = "UIX_ExerciseCode" });

        var slugIndex = new CreateIndexModel<ExerciseCatalog>(
            ix.Ascending(x => x.Slug),
            new CreateIndexOptions { Unique = true, Name = "UIX_Slug" });

        var textIndex = new CreateIndexModel<ExerciseCatalog>(
            ix.Text(x => x.NameVi).Text(x => x.NameEn),
            new CreateIndexOptions { Name = "TXT_Search_Names" });

        var aiFilterIndex = new CreateIndexModel<ExerciseCatalog>(
            ix.Ascending(x => x.BodyRegion).Ascending(x => x.MovementPattern),
            new CreateIndexOptions { Name = "IX_AI_BodyRegion_Movement" });

        var categoryDiffIndex = new CreateIndexModel<ExerciseCatalog>(
            ix.Ascending(x => x.Category).Ascending(x => x.Difficulty),
            new CreateIndexOptions { Name = "IX_UI_Category_Difficulty" });

        await collection.Indexes.CreateManyAsync(
        [
            codeIndex,
            slugIndex,
            textIndex,
            aiFilterIndex,
            categoryDiffIndex
        ]);
    }

    private static async Task ConfigureExerciseMotionAssetIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<ExerciseMotionAsset>("ExerciseMotionAsset");
        var ix = Builders<ExerciseMotionAsset>.IndexKeys;

        var exerciseAssetIndex = new CreateIndexModel<ExerciseMotionAsset>(
            ix.Ascending(x => x.ExerciseId).Ascending(x => x.AssetType),
            new CreateIndexOptions { Name = "IX_ExerciseId_AssetType" });

        await collection.Indexes.CreateOneAsync(exerciseAssetIndex);
    }

    private static async Task ConfigureWorkoutTemplateIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<WorkoutTemplate>("WorkoutTemplates");
        var ix = Builders<WorkoutTemplate>.IndexKeys;

        var systemTemplateIndex = new CreateIndexModel<WorkoutTemplate>(
            ix.Ascending(x => x.IsSystemTemplate)
              .Ascending(x => x.Difficulty)
              .Ascending(x => x.Goal),
            new CreateIndexOptions { Name = "IX_SystemTemplate_Diff_Goal" });

        await collection.Indexes.CreateOneAsync(systemTemplateIndex);
    }
}
