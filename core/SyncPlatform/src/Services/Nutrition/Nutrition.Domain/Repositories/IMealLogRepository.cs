using Nutrition.Domain.Models;

namespace Nutrition.Domain.Repositories;

public interface IMealLogRepository : IGenericRepository<MealLog>
{
    Task<MealLog?> GetByRelatedOrderIdAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MealLog>> GetByUserAndDateRangeAsync(
        Guid userId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default);
}
