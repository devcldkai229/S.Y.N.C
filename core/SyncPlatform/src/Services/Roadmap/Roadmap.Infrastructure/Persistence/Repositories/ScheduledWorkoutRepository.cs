using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class ScheduledWorkoutRepository : GenericRepository<ScheduledWorkout>, IScheduledWorkoutRepository
{
    public ScheduledWorkoutRepository(IMongoDatabase database)
        : base(database, "ScheduledWorkouts") { }

    public async Task<IReadOnlyList<ScheduledWorkout>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId)
            .SortBy(x => x.ScheduledStartTime)
            .ToListAsync(cancellationToken);

    public async Task<ScheduledWorkout?> GetBySessionIdAsync(
        Guid sessionId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.SessionId == sessionId)
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlyList<ScheduledWorkout>> GetByUserIdAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId
                     && x.ScheduledStartTime >= from
                     && x.ScheduledStartTime <= to)
            .SortBy(x => x.ScheduledStartTime)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<ScheduledWorkout>> GetBySessionIdsAsync(
        IEnumerable<Guid> sessionIds,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => sessionIds.Contains(x.SessionId))
            .ToListAsync(cancellationToken);
}
