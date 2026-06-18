using Exercise.Domain.Models;

namespace Exercise.Domain.Repositories;

public interface IExerciseMotionAssetRepository : IGenericRepository<ExerciseMotionAsset>
{
    Task<IReadOnlyList<ExerciseMotionAsset>> GetByExerciseIdAsync(Guid exerciseId, CancellationToken cancellationToken = default);

    Task<IReadOnlyDictionary<Guid, ExerciseMotionAsset>> GetPrimaryImagesByExerciseIdsAsync(
        IReadOnlyList<Guid> exerciseIds,
        CancellationToken cancellationToken = default);
}
