using Exercise.Application.Common;
using Exercise.Application.DTOs;

namespace Exercise.Application.Services;

public interface IWorkoutTemplateService
{
    Task<(IReadOnlyList<WorkoutTemplateDto> Items, PaginationMetadata Pagination)> GetAllAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<WorkoutTemplateDto> Items, PaginationMetadata Pagination)> GetSystemTemplatesAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<WorkoutTemplateDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<WorkoutTemplateDto> CreateAsync(CreateWorkoutTemplateDto dto, CancellationToken cancellationToken = default);
    Task UpdateAsync(Guid id, UpdateWorkoutTemplateDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
