using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IWorkoutExecutionLogService
{
    Task<WorkoutExecutionLogDto> CreateAsync(CreateWorkoutExecutionLogDto dto, CancellationToken cancellationToken = default);
    Task<WorkoutExecutionLogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<WorkoutExecutionLogDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
    Task<WorkoutExecutionLogDto> UpdateAsync(Guid id, UpdateWorkoutExecutionLogDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
