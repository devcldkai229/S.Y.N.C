using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IExerciseSetLogRepository : IGenericRepository<ExerciseSetLog>
{
    Task<IReadOnlyList<ExerciseSetLog>> GetByExecutionIdAsync(Guid executionId, CancellationToken cancellationToken = default);
    Task CreateManyAsync(IEnumerable<ExerciseSetLog> entities, CancellationToken cancellationToken = default);
}
