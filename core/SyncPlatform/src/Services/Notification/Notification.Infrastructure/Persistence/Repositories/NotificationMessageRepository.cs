using Notification.Domain.Models;
using Notification.Domain.Enums;
using Notification.Domain.Repositories;
using MongoDB.Driver;

namespace Notification.Infrastructure.Persistence.Repositories;

public class NotificationMessageRepository : GenericRepository<NotificationMessage>, INotificationMessageRepository
{
    public NotificationMessageRepository(IMongoDatabase database) : base(database, "NotificationMessages")
    {
    }

    public async Task<(IReadOnlyList<NotificationMessage> Items, int TotalRecords)> GetPagedByUserIdAsync(
        Guid userId, 
        int pageNumber, 
        int pageSize, 
        NotificationStatus? status = null, 
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<NotificationMessage>.Filter;
        var filter = builder.Eq(x => x.UserId, userId);

        if (status.HasValue)
        {
            filter &= builder.Eq(x => x.Status, status.Value);
        }

        var totalRecords = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalRecords);
    }

    public async Task<int> GetUnreadCountByUserIdAsync(
    Guid userId,
    CancellationToken cancellationToken = default)
    {
        var builder = Builders<NotificationMessage>.Filter;

        var unreadStatuses = new[]
        {
        NotificationStatus.Sent,
        NotificationStatus.Delivered
    };

        var filter = builder.Eq(x => x.UserId, userId)
            & builder.In(x => x.Status, unreadStatuses);

        return (int)await Collection.CountDocumentsAsync(
            filter,
            cancellationToken: cancellationToken);
    }

    public async Task MarkAllAsReadByUserIdAsync(
     Guid userId,
     CancellationToken cancellationToken = default)
    {
        var builder = Builders<NotificationMessage>.Filter;

        var readableStatuses = new[]
        {
        NotificationStatus.Sent,
        NotificationStatus.Delivered
    };

        var filter = builder.Eq(x => x.UserId, userId)
            & builder.In(x => x.Status, readableStatuses);

        var now = DateTimeOffset.UtcNow;

        var update = Builders<NotificationMessage>.Update
            .Set(x => x.Status, NotificationStatus.Read)
            .Set(x => x.ReadAt, now)
            .Set(x => x.UpdatedAt, now);

        await Collection.UpdateManyAsync(
            filter,
            update,
            cancellationToken: cancellationToken);
    }
}
