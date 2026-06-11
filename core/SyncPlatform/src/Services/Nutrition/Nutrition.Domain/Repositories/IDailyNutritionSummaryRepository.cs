using Nutrition.Domain.Models;

namespace Nutrition.Domain.Repositories;

public interface IDailyNutritionSummaryRepository : IGenericRepository<DailyNutritionSummary>
{
    Task<DailyNutritionSummary?> GetByUserAndDateAsync(
        Guid userId,
        DateOnly date,
        CancellationToken cancellationToken = default);

    Task UpsertAsync(DailyNutritionSummary summary, CancellationToken cancellationToken = default);
}
