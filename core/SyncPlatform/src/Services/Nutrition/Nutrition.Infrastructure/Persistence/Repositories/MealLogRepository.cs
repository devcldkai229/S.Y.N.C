using MongoDB.Driver;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Infrastructure.Persistence.Repositories;

public class MealLogRepository : GenericRepository<MealLog>, IMealLogRepository
{
    public MealLogRepository(IMongoDatabase database) : base(database, "MealLogs")
    {
    }

    public async Task<MealLog?> GetByRelatedOrderIdAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.RelatedOrderId == orderId).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MealLog>> GetByUserAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.UserId == userId && x.LoggedAt >= from && x.LoggedAt < to)
            .SortByDescending(x => x.LoggedAt)
            .ToListAsync(cancellationToken);
    }
}
