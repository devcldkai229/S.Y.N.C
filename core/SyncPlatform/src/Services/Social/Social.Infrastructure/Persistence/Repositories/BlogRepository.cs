using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class BlogRepository : IBlogRepository
{
    private readonly IMongoCollection<Blog> _collection;

    public BlogRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<Blog>("Blogs");
    }

    public Task<Blog?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _collection.Find(x => x.Id == id).FirstOrDefaultAsync(cancellationToken)!;

    public Task<Blog?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default) =>
        _collection.Find(x => x.Slug == slug).FirstOrDefaultAsync(cancellationToken)!;

    public async Task<bool> SlugExistsAsync(
        string slug,
        Guid? excludeBlogId = null,
        CancellationToken cancellationToken = default)
    {
        var filter = excludeBlogId.HasValue
            ? Builders<Blog>.Filter.And(
                Builders<Blog>.Filter.Eq(x => x.Slug, slug),
                Builders<Blog>.Filter.Ne(x => x.Id, excludeBlogId.Value))
            : Builders<Blog>.Filter.Eq(x => x.Slug, slug);

        return await _collection.Find(filter).AnyAsync(cancellationToken);
    }

    public async Task CreateAsync(Blog blog, CancellationToken cancellationToken = default)
    {
        blog.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(blog, cancellationToken: cancellationToken);
    }

    public async Task UpdateAsync(Blog blog, CancellationToken cancellationToken = default)
    {
        blog.UpdatedAt = DateTimeOffset.UtcNow;
        await _collection.ReplaceOneAsync(
            x => x.Id == blog.Id,
            blog,
            cancellationToken: cancellationToken);
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var result = await _collection.DeleteOneAsync(x => x.Id == id, cancellationToken);
        return result.DeletedCount > 0;
    }

    public async Task<(IReadOnlyList<Blog> Items, int TotalRecords)> GetPublishedAsync(
        int pageNumber,
        int pageSize,
        string? tag,
        CancellationToken cancellationToken = default)
    {
        var filters = new List<FilterDefinition<Blog>>
        {
            Builders<Blog>.Filter.Eq(x => x.Status, BlogStatus.Published),
        };

        if (!string.IsNullOrWhiteSpace(tag))
        {
            filters.Add(Builders<Blog>.Filter.AnyEq(
                x => x.Tags,
                tag.Trim().ToLowerInvariant()));
        }

        var filter = Builders<Blog>.Filter.And(filters);
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await _collection.Find(filter)
            .SortByDescending(x => x.PublishedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<(IReadOnlyList<Blog> Items, int TotalRecords)> GetByAuthorAsync(
        Guid authorId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<Blog>.Filter.Eq(x => x.AuthorId, authorId);
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await _collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<bool> IncrementLikeCountAsync(Guid blogId, CancellationToken cancellationToken = default)
    {
        var update = Builders<Blog>.Update
            .Inc(x => x.LikeCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _collection.UpdateOneAsync(x => x.Id == blogId, update, cancellationToken: cancellationToken);
        return result.ModifiedCount > 0;
    }

    public async Task<bool> IncrementShareCountAsync(Guid blogId, CancellationToken cancellationToken = default)
    {
        var update = Builders<Blog>.Update
            .Inc(x => x.ShareCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _collection.UpdateOneAsync(x => x.Id == blogId, update, cancellationToken: cancellationToken);
        return result.ModifiedCount > 0;
    }
}
