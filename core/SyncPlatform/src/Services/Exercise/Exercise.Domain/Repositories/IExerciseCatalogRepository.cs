using Exercise.Domain.Common;
using Exercise.Domain.Models;

namespace Exercise.Domain.Repositories;

public interface IExerciseCatalogRepository : IGenericRepository<ExerciseCatalog>
{
    Task<ExerciseCatalog?> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<ExerciseCatalog?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<ExerciseCatalog> Items, int TotalRecords)> SearchActivePagedAsync(
        ExerciseCatalogSearchCriteria criteria,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ExerciseCatalog>> GetForEnrichmentAsync(
        bool force,
        int? limit,
        CancellationToken cancellationToken = default);

    Task<int> ApproveEnrichmentAsync(int? limit, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ExerciseCatalog>> GetAllActiveAsync(
        int? limit,
        CancellationToken cancellationToken = default);
}
