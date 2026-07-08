using Notification.Domain.Models;
using Notification.Domain.Enums;
using Notification.Domain.Repositories;
using MongoDB.Driver;
using MongoDB.Bson;

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

    public async Task<bool> HasSmartPushSentTodayAsync(
        Guid userId,
        DateTimeOffset utcNow,
        string timeZoneId,
        CancellationToken cancellationToken)
    {
        var tzId = string.IsNullOrWhiteSpace(timeZoneId) ? "Asia/Ho_Chi_Minh" : timeZoneId;
        TimeZoneInfo userTz;
        try
        {
            userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
        }
        catch (Exception)
        {
            tzId = "Asia/Ho_Chi_Minh";
            userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
        }

        var userLocalNow = TimeZoneInfo.ConvertTime(utcNow, userTz);
        var localStartOfToday = new DateTime(userLocalNow.Year, userLocalNow.Month, userLocalNow.Day, 0, 0, 0, DateTimeKind.Unspecified);
        var startOfToday = new DateTimeOffset(localStartOfToday, userTz.GetUtcOffset(localStartOfToday));
        var startOfTomorrow = startOfToday.AddDays(1);

        var builder = Builders<NotificationMessage>.Filter;
        var filter = builder.Eq(x => x.UserId, userId);
        filter &= builder.Ne(x => x.Status, NotificationStatus.Failed);
        filter &= builder.Ne(x => x.Status, NotificationStatus.Cancelled);

        var dateFilter = builder.Or(
            builder.And(builder.Gte(x => x.CreatedAt, startOfToday), builder.Lt(x => x.CreatedAt, startOfTomorrow)),
            builder.And(builder.Ne(x => x.SentAt, null), builder.Gte(x => x.SentAt, startOfToday), builder.Lt(x => x.SentAt, startOfTomorrow))
        );
        filter &= dateFilter;

        filter &= builder.Regex(x => x.DataPayloadJson, new BsonRegularExpression("SmartPushNotificationEngine"));

        var count = await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        return count > 0;
    }

    public async Task<IReadOnlyList<string>> GetScheduledTopicsForDateAsync(
        Guid userId,
        string userLocalDate,
        CancellationToken cancellationToken)
    {
        var builder = Builders<NotificationMessage>.Filter;
        var filter = builder.Eq(x => x.UserId, userId)
                     & builder.Eq(x => x.UserLocalDate, userLocalDate)
                     & builder.Ne(x => x.Status, NotificationStatus.Cancelled)
                     & builder.Ne(x => x.Status, NotificationStatus.Failed);

        var messages = await Collection.Find(filter).ToListAsync(cancellationToken);
        return messages
            .Where(x => !string.IsNullOrEmpty(x.SmartPushTopic))
            .Select(x => x.SmartPushTopic!)
            .ToList();
    }

    public async Task<NotificationMessage?> ClaimPendingMessageAsync(
        Guid messageId,
        CancellationToken cancellationToken)
    {
        var builder = Builders<NotificationMessage>.Filter;
        var filter = builder.Eq(x => x.Id, messageId)
                     & builder.Eq(x => x.Status, NotificationStatus.Pending);

        var update = Builders<NotificationMessage>.Update
            .Set(x => x.Status, NotificationStatus.Processing)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        return await Collection.FindOneAndUpdateAsync(
            filter,
            update,
            new FindOneAndUpdateOptions<NotificationMessage> { ReturnDocument = ReturnDocument.After },
            cancellationToken);
    }

    public async Task<IReadOnlyList<NotificationMessage>> GetDuePendingMessagesAsync(
        DateTimeOffset time,
        CancellationToken cancellationToken)
    {
        var builder = Builders<NotificationMessage>.Filter;
        var filter = builder.Eq(x => x.Status, NotificationStatus.Pending)
                     & builder.Lte(x => x.ScheduledFor, time);

        return await Collection.Find(filter).ToListAsync(cancellationToken);
    }
}
