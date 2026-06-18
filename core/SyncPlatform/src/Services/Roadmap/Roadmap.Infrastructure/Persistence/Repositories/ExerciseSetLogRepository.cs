using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class ExerciseSetLogRepository : GenericRepository<ExerciseSetLog>, IExerciseSetLogRepository
{
    public ExerciseSetLogRepository(IMongoDatabase database)
        : base(database, "ExerciseSetLogs") { }

    public async Task<IReadOnlyList<ExerciseSetLog>> GetByExecutionIdAsync(
        Guid executionId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.ExecutionId == executionId)
            .SortBy(x => x.SetNumber)
            .ToListAsync(cancellationToken);

    public async Task CreateManyAsync(
        IEnumerable<ExerciseSetLog> entities,
        CancellationToken cancellationToken = default)
    {
        var list = entities.ToList();
        var now = DateTimeOffset.UtcNow;
        foreach (var entity in list)
            entity.CreatedAt = now;

        await Collection.InsertManyAsync(list, cancellationToken: cancellationToken);
    }

    public async Task DeleteManyByExecutionIdAsync(
        Guid executionId,
        CancellationToken cancellationToken = default)
    {
        await Collection.DeleteManyAsync(x => x.ExecutionId == executionId, cancellationToken);
    }
}
