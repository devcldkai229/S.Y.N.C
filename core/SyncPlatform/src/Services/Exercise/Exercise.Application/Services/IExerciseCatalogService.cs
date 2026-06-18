using Exercise.Application.Common;
using Exercise.Application.DTOs;

namespace Exercise.Application.Services;

public interface IExerciseCatalogService
{
    Task<(IReadOnlyList<ExerciseCatalogDto> Items, PaginationMetadata Pagination)> SearchActiveAsync(
        ExerciseSearchRequest request,
        CancellationToken cancellationToken = default);

    Task<ExerciseCatalogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<ExerciseCatalogDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<ExerciseCatalogDto> GetBySlugAsync(string slug, CancellationToken cancellationToken = default);
    Task<ExerciseCatalogDto> CreateAsync(CreateExerciseCatalogDto dto, CancellationToken cancellationToken = default);
    Task UpdateAsync(Guid id, UpdateExerciseCatalogDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<ExerciseCatalogDetailDto> GetDetailAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyDictionary<Guid, string?>> GetThumbnailUrlsAsync(
        IReadOnlyList<Guid> exerciseIds,
        CancellationToken cancellationToken = default);
}
