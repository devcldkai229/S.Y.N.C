using Exercise.Domain.Models;

namespace Exercise.Domain.Repositories;

public interface IWorkoutTemplateRepository : IGenericRepository<WorkoutTemplate>
{
    Task<(IReadOnlyList<WorkoutTemplate> Items, int TotalRecords)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<WorkoutTemplate> Items, int TotalRecords)> GetSystemTemplatesPagedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}
