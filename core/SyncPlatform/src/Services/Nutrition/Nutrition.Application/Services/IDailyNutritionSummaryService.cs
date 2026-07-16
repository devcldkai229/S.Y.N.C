using Nutrition.Application.DTOs;

namespace Nutrition.Application.Services;

public interface IDailyNutritionSummaryService
{
    Task<DailyNutritionSummaryDto> GetDailySummaryAsync(
        Guid userId,
        DateOnly date,
        CancellationToken cancellationToken = default);

    Task<DailyNutritionSummaryDto> AddWaterIntakeAsync(
        Guid userId,
        AddWaterIntakeDto dto,
        CancellationToken cancellationToken = default);

    Task RecomputeForDateAsync(Guid userId, DateOnly date, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<NutritionTimeseriesBucketDto>> GetTimeseriesAsync(
        Guid userId,
        DateOnly from,
        DateOnly to,
        string granularity,
        CancellationToken cancellationToken = default);
}
