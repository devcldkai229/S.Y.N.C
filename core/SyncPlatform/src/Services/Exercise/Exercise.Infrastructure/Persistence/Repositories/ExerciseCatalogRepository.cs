using Exercise.Domain.Common;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence.Repositories;

public class ExerciseCatalogRepository : GenericRepository<ExerciseCatalog>, IExerciseCatalogRepository
{
    public ExerciseCatalogRepository(IMongoDatabase database) : base(database, "ExerciseCatalog")
    {
    }

    public async Task<ExerciseCatalog?> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.ExerciseCode == code).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<ExerciseCatalog?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.Slug == slug).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<ExerciseCatalog> Items, int TotalRecords)> SearchActivePagedAsync(
        ExerciseCatalogSearchCriteria criteria,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<ExerciseCatalog>.Filter;
        var filter = builder.Eq(x => x.IsActive, true);

        if (!string.IsNullOrWhiteSpace(criteria.Query))
        {
            var query = criteria.Query.Trim();
            var regex = new BsonRegularExpression(query, "i");

            var searchFilter = builder.Or(
                builder.Regex(nameof(ExerciseCatalog.ExerciseCode), regex),
                builder.Regex(nameof(ExerciseCatalog.NameEn), regex),
                builder.Regex(nameof(ExerciseCatalog.NameVi), regex),
                builder.Regex(nameof(ExerciseCatalog.Slug), regex),
                builder.Regex(nameof(ExerciseCatalog.Category), regex),
                builder.Regex(nameof(ExerciseCatalog.Difficulty), regex),
                builder.Regex(nameof(ExerciseCatalog.MovementPattern), regex),
                builder.Regex(nameof(ExerciseCatalog.BodyRegion), regex),
                builder.Regex(nameof(ExerciseCatalog.PrimaryMuscles), regex),
                builder.Regex(nameof(ExerciseCatalog.SecondaryMuscles), regex),
                builder.Regex(nameof(ExerciseCatalog.EquipmentRequired), regex),
                builder.Regex(nameof(ExerciseCatalog.MovementTags), regex)
            );

            if (Guid.TryParse(query, out var id))
            {
                searchFilter = builder.Or(
                    searchFilter,
                    builder.Eq(x => x.Id, id)
                );
            }

            filter = builder.And(filter, searchFilter);
        }

        if (criteria.Category.HasValue)
        {
            filter = builder.And(filter, builder.Eq(x => x.Category, criteria.Category.Value));
        }

        if (criteria.Difficulty.HasValue)
        {
            filter = builder.And(filter, builder.Eq(x => x.Difficulty, criteria.Difficulty.Value));
        }

        if (criteria.BodyRegion.HasValue)
        {
            filter = builder.And(filter, builder.Eq(x => x.BodyRegion, criteria.BodyRegion.Value));
        }

        if (criteria.MovementPattern.HasValue)
        {
            filter = builder.And(filter, builder.Eq(x => x.MovementPattern, criteria.MovementPattern.Value));
        }

        if (!string.IsNullOrWhiteSpace(criteria.PrimaryMuscle))
        {
            var muscleRegex = new BsonRegularExpression("^" + System.Text.RegularExpressions.Regex.Escape(criteria.PrimaryMuscle.Trim()) + "$", "i");
            filter = builder.And(filter, builder.Regex(nameof(ExerciseCatalog.PrimaryMuscles), muscleRegex));
        }

        if (!string.IsNullOrWhiteSpace(criteria.Equipment))
        {
            var eqRegex = new BsonRegularExpression("^" + System.Text.RegularExpressions.Regex.Escape(criteria.Equipment.Trim()) + "$", "i");
            filter = builder.And(filter, builder.Regex(nameof(ExerciseCatalog.EquipmentRequired), eqRegex));
        }

        var totalRecords = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await Collection.Find(filter)
            .SortBy(x => x.NameEn)
            .ThenBy(x => x.ExerciseCode)
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Limit(criteria.PageSize)
            .ToListAsync(cancellationToken);

        return (items, totalRecords);
    }

    public async Task<IReadOnlyList<ExerciseCatalog>> GetForEnrichmentAsync(
        bool force,
        int? limit,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<ExerciseCatalog>.Filter;
        var filter = builder.Eq(x => x.IsActive, true);

        if (!force)
        {
            // Match null AND missing field (imported docs omit AiEnrichedAt via BsonIgnoreIfNull).
            var notEnriched = builder.Or(
                builder.Eq(x => x.AiEnrichedAt, (DateTimeOffset?)null),
                builder.Exists(x => x.AiEnrichedAt, false));
            filter = builder.And(filter, notEnriched);
        }

        IFindFluent<ExerciseCatalog, ExerciseCatalog> query = Collection.Find(filter);
        query = query.SortBy(x => x.ExerciseCode);
        if (limit.HasValue)
        {
            query = query.Limit(limit.Value);
        }

        return await query.ToListAsync(cancellationToken);
    }

    public async Task<int> ApproveEnrichmentAsync(int? limit, CancellationToken cancellationToken = default)
    {
        var builder = Builders<ExerciseCatalog>.Filter;
        var filter = builder.And(
            builder.Eq(x => x.NeedsReview, true),
            builder.Ne(x => x.AiEnrichedAt, null));

        IFindFluent<ExerciseCatalog, ExerciseCatalog> query = Collection.Find(filter);
        query = query.SortBy(x => x.ExerciseCode);
        if (limit.HasValue)
        {
            query = query.Limit(limit.Value);
        }

        var items = await query.ToListAsync(cancellationToken);
        foreach (var item in items)
        {
            item.NeedsReview = false;
            item.UpdatedAt = DateTimeOffset.UtcNow;
            await Collection.ReplaceOneAsync(x => x.Id == item.Id, item, cancellationToken: cancellationToken);
        }

        return items.Count;
    }

    public async Task<IReadOnlyList<ExerciseCatalog>> GetAllActiveAsync(
        int? limit,
        CancellationToken cancellationToken = default)
    {
        IFindFluent<ExerciseCatalog, ExerciseCatalog> query = Collection
            .Find(x => x.IsActive)
            .SortBy(x => x.ExerciseCode);

        if (limit.HasValue)
            query = query.Limit(limit.Value);

        return await query.ToListAsync(cancellationToken);
    }
}
