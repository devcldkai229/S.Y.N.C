using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IUserCustomWorkoutRepository : IGenericRepository<UserCustomWorkout>
{
    Task<IReadOnlyList<UserCustomWorkout>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
}
