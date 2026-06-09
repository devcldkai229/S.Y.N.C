using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence.Repositories;

public class WorkoutTemplateRepository : GenericRepository<WorkoutTemplate>, IWorkoutTemplateRepository
{
    public WorkoutTemplateRepository(IMongoDatabase database) : base(database, "WorkoutTemplate")
    {
    }

    public async Task<(IReadOnlyList<WorkoutTemplate> Items, int TotalRecords)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<WorkoutTemplate>.Filter;
        var filter = builder.Empty;

        var totalRecords = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortBy(x => x.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalRecords);
    }

    public async Task<(IReadOnlyList<WorkoutTemplate> Items, int TotalRecords)> GetSystemTemplatesPagedAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<WorkoutTemplate>.Filter;
        var filter = builder.Eq(x => x.IsSystemTemplate, true);

        var totalRecords = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortBy(x => x.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalRecords);
    }
}
