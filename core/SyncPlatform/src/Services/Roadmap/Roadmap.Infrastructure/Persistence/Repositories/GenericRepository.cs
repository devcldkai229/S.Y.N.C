using System.Linq.Expressions;
using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class GenericRepository<TEntity> : IGenericRepository<TEntity>
    where TEntity : BaseMongoEntity
{
    protected readonly IMongoCollection<TEntity> Collection;

    public GenericRepository(IMongoDatabase database, string collectionName)
    {
        Collection = database.GetCollection<TEntity>(collectionName);
    }

    public virtual async Task<IReadOnlyList<TEntity>> GetAllAsync(CancellationToken cancellationToken = default)
        => await Collection.Find(_ => true).ToListAsync(cancellationToken);

    public virtual async Task<TEntity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await Collection.Find(x => x.Id == id).FirstOrDefaultAsync(cancellationToken);

    public virtual async Task CreateAsync(TEntity entity, CancellationToken cancellationToken = default)
    {
        entity.CreatedAt = DateTimeOffset.UtcNow;
        await Collection.InsertOneAsync(entity, cancellationToken: cancellationToken);
    }

    public virtual async Task UpdateAsync(Guid id, TEntity entity, CancellationToken cancellationToken = default)
    {
        entity.UpdatedAt = DateTimeOffset.UtcNow;
        await Collection.ReplaceOneAsync(x => x.Id == id, entity, cancellationToken: cancellationToken);
    }

    public virtual async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
        => await Collection.DeleteOneAsync(x => x.Id == id, cancellationToken);

    public virtual async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var count = await Collection.CountDocumentsAsync(x => x.Id == id, cancellationToken: cancellationToken);
        return count > 0;
    }

    public virtual async Task<(IReadOnlyList<TEntity> Items, int TotalCount)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Expression<Func<TEntity, bool>>? filter = null,
        CancellationToken cancellationToken = default)
    {
        var filterDef = filter ?? (_ => true);
        var totalCount = (int)await Collection.CountDocumentsAsync(filterDef, cancellationToken: cancellationToken);
        var items = await Collection.Find(filterDef)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);
        return (items, totalCount);
    }
}

