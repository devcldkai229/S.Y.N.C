using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IScheduledWorkoutRepository : IGenericRepository<ScheduledWorkout>
{
    Task<IReadOnlyList<ScheduledWorkout>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<ScheduledWorkout?> GetBySessionIdAsync(Guid sessionId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ScheduledWorkout>> GetByUserIdAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ScheduledWorkout>> GetBySessionIdsAsync(
        IEnumerable<Guid> sessionIds,
        CancellationToken cancellationToken = default);
}
