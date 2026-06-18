using MongoDB.Driver;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Infrastructure.Persistence.Repositories;

public class DailyNutritionSummaryRepository : GenericRepository<DailyNutritionSummary>, IDailyNutritionSummaryRepository
{
    public DailyNutritionSummaryRepository(IMongoDatabase database) : base(database, "DailyNutritionSummaries")
    {
    }

    public async Task<DailyNutritionSummary?> GetByUserAndDateAsync(
        Guid userId,
        DateOnly date,
        CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.UserId == userId && x.Date == date).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task UpsertAsync(DailyNutritionSummary summary, CancellationToken cancellationToken = default)
    {
        var existing = await GetByUserAndDateAsync(summary.UserId, summary.Date, cancellationToken);
        if (existing == null)
        {
            summary.CreatedAt = DateTimeOffset.UtcNow;
            await Collection.InsertOneAsync(summary, cancellationToken: cancellationToken);
            return;
        }

        summary.Id = existing.Id;
        summary.CreatedAt = existing.CreatedAt;
        summary.UpdatedAt = DateTimeOffset.UtcNow;
        await Collection.ReplaceOneAsync(x => x.Id == existing.Id, summary, cancellationToken: cancellationToken);
    }
}
