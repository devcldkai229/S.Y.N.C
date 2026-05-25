using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IScheduledWorkoutService
{
    Task<ScheduledWorkoutDto> CreateAsync(CreateScheduledWorkoutDto dto, CancellationToken cancellationToken = default);
    Task<ScheduledWorkoutDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<ScheduledWorkoutDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
    Task<ScheduledWorkoutDto> UpdateAsync(Guid id, UpdateScheduledWorkoutDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
