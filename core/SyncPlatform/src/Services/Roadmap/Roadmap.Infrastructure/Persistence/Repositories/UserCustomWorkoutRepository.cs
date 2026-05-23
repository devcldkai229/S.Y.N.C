using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class UserCustomWorkoutRepository : GenericRepository<UserCustomWorkout>, IUserCustomWorkoutRepository
{
    public UserCustomWorkoutRepository(IMongoDatabase database)
        : base(database, "UserCustomWorkouts") { }

    public async Task<IReadOnlyList<UserCustomWorkout>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
}
