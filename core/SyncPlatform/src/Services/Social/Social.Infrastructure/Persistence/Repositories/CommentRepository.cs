using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class CommentRepository : ICommentRepository
{
    private readonly IMongoCollection<Comment> _collection;

    public CommentRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<Comment>("Comments");
    }

    public async Task<Comment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await _collection.Find(x => x.Id == id).FirstOrDefaultAsync(cancellationToken);

    public async Task<Comment> CreateAsync(Comment comment, CancellationToken cancellationToken = default)
    {
        comment.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(comment, cancellationToken: cancellationToken);
        return comment;
    }

    public async Task<(IReadOnlyList<Comment> Items, int TotalRecords)> GetByPostIdAsync(
        Guid postId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<Comment>.Filter.Eq(x => x.PostId, postId);
        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await _collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }
}
