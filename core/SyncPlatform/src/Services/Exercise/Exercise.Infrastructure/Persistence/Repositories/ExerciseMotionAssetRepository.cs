using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Libs.Shared.Enums;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence.Repositories;

public class ExerciseMotionAssetRepository : GenericRepository<ExerciseMotionAsset>, IExerciseMotionAssetRepository
{
    public ExerciseMotionAssetRepository(IMongoDatabase database) : base(database, "ExerciseMotionAsset")
    {
    }

    public async Task<IReadOnlyList<ExerciseMotionAsset>> GetByExerciseIdAsync(Guid exerciseId, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.ExerciseId == exerciseId).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyDictionary<Guid, ExerciseMotionAsset>> GetPrimaryImagesByExerciseIdsAsync(
        IReadOnlyList<Guid> exerciseIds,
        CancellationToken cancellationToken = default)
    {
        if (exerciseIds.Count == 0)
            return new Dictionary<Guid, ExerciseMotionAsset>();

        var filter = Builders<ExerciseMotionAsset>.Filter.And(
            Builders<ExerciseMotionAsset>.Filter.In(x => x.ExerciseId, exerciseIds),
            Builders<ExerciseMotionAsset>.Filter.Eq(x => x.AssetType, AssetType.Image));

        var assets = await Collection.Find(filter).ToListAsync(cancellationToken);

        return assets
            .GroupBy(a => a.ExerciseId)
            .ToDictionary(g => g.Key, g => g.First());
    }
}
