using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class RecoveryProfileRepository : GenericRepository<RecoveryProfile>, IRecoveryProfileRepository
{
    public RecoveryProfileRepository(IMongoDatabase database)
        : base(database, "RecoveryProfiles") { }

    public async Task<RecoveryProfile?> GetLatestByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await Collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }
}
