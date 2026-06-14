using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IWorkoutExecutionLogRepository : IGenericRepository<WorkoutExecutionLog>
{
    Task<IReadOnlyList<WorkoutExecutionLog>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<WorkoutExecutionLog?> GetBySessionIdAsync(Guid sessionId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<WorkoutExecutionLog>> GetByUserIdAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default);
    Task<WorkoutExecutionLog?> GetActiveExecutionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken = default);
}
