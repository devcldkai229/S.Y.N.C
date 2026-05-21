using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class WorkoutExecutionLogRepository : GenericRepository<WorkoutExecutionLog>, IWorkoutExecutionLogRepository
{
    public WorkoutExecutionLogRepository(IMongoDatabase database)
        : base(database, "WorkoutExecutionLogs") { }

    public async Task<IReadOnlyList<WorkoutExecutionLog>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.StartedAt)
            .ToListAsync(cancellationToken);

    public async Task<WorkoutExecutionLog?> GetBySessionIdAsync(
        Guid sessionId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.SessionId == sessionId)
            .FirstOrDefaultAsync(cancellationToken);
}
