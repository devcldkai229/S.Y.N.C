using Nutrition.Application.DTOs;

namespace Nutrition.Application.Services;

public interface IMealLogService
{
    Task<MealLogDto> CreateAsync(Guid userId, CreateMealLogDto dto, CancellationToken cancellationToken = default);

    Task<MealLogDto> UpdateAsync(Guid userId, Guid id, UpdateMealLogDto dto, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid userId, Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MealLogDto>> ListAsync(
        Guid userId,
        MealLogListRequest request,
        CancellationToken cancellationToken = default);

    Task<MealLogDto> GetByIdAsync(Guid userId, Guid id, CancellationToken cancellationToken = default);
}
