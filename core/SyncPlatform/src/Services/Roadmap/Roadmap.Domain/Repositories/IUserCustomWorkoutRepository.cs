using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IUserCustomWorkoutRepository : IGenericRepository<UserCustomWorkout>
{
    Task<IReadOnlyList<UserCustomWorkout>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<UserCustomWorkout> Items, int TotalCount)> GetPublicPagedAsync(
        int pageNumber,
        int pageSize,
        string? search = null,
        string? sortBy = null,
        CancellationToken cancellationToken = default);
}
