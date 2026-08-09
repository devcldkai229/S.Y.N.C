using MongoDB.Driver;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public sealed class ContentReportRepository : IContentReportRepository
{
    private readonly IMongoCollection<ContentReport> _collection;

    public ContentReportRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<ContentReport>("ContentReports");
    }

    public async Task CreateAsync(ContentReport report, CancellationToken cancellationToken = default)
    {
        report.CreatedAt = DateTimeOffset.UtcNow;
        await _collection.InsertOneAsync(report, cancellationToken: cancellationToken);
    }

    public async Task<(IReadOnlyList<ContentReport> Items, int Total)> ListAsync(
        string? status,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var filter = string.IsNullOrWhiteSpace(status)
            ? Builders<ContentReport>.Filter.Empty
            : Builders<ContentReport>.Filter.Eq(r => r.Status, status.Trim());

        var total = (int)await _collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await _collection
            .Find(filter)
            .SortByDescending(r => r.CreatedAt)
            .Skip(skip)
            .Limit(take)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<ContentReport?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _collection.Find(r => r.Id == id).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task UpdateStatusAsync(Guid id, string status, CancellationToken cancellationToken = default)
    {
        var update = Builders<ContentReport>.Update
            .Set(r => r.Status, status)
            .Set(r => r.UpdatedAt, DateTimeOffset.UtcNow);

        await _collection.UpdateOneAsync(
            r => r.Id == id,
            update,
            cancellationToken: cancellationToken);
    }
}
