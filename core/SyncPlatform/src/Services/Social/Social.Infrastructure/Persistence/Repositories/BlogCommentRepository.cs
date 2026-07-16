using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class BlogCommentRepository : IBlogCommentRepository
{
    private readonly IMongoCollection<BlogComment> _collection;

    public BlogCommentRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<BlogComment>("BlogComments");
    }

    public async Task<BlogComment> CreateAsync(BlogComment comment, CancellationToken cancellationToken = default)
    {
        comment.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(comment, cancellationToken: cancellationToken);
        return comment;
    }

    public async Task<(IReadOnlyList<BlogComment> Items, int TotalRecords)> GetByBlogIdAsync(
        Guid blogId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<BlogComment>.Filter.Eq(x => x.BlogId, blogId);
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await _collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }
}
