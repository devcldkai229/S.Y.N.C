using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IExerciseSetLogService
{
    Task<ExerciseSetLogDto> CreateAsync(CreateExerciseSetLogDto dto, CancellationToken cancellationToken = default);
    Task<ExerciseSetLogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<ExerciseSetLogDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? executionId = null,
        CancellationToken cancellationToken = default);
}
