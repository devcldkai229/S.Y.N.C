using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
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
}
