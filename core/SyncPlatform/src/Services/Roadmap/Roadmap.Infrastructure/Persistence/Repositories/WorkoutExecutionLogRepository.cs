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

    public async Task<IReadOnlyList<WorkoutExecutionLog>> GetByUserIdAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId
                     && x.StartedAt >= from
                     && x.StartedAt < to)
            .SortByDescending(x => x.StartedAt)
            .ToListAsync(cancellationToken);

    public async Task<WorkoutExecutionLog?> GetActiveExecutionAsync(
        Guid userId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId && x.SessionId == sessionId && x.CompletedAt == null)
            .FirstOrDefaultAsync(cancellationToken);
}
