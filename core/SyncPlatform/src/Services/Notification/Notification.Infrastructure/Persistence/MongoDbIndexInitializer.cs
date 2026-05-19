using MongoDB.Driver;
using Notification.Domain.Models;

namespace Notification.Infrastructure.Persistence;

/// <summary>
/// Khởi tạo tất cả indexes cho Notification service.
/// Được gọi một lần khi app startup — idempotent, an toàn trên mọi lần deploy.
/// </summary>
public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigureNotificationMessageIndexesAsync(database);
        await ConfigureNotificationTemplateIndexesAsync(database);
    }

    private static async Task ConfigureNotificationMessageIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<NotificationMessage>("NotificationMessages");
        var ix = Builders<NotificationMessage>.IndexKeys;

        // Inbox query: toàn bộ thông báo của user theo trạng thái (Unread, All...)
        var userStatusIndex = new CreateIndexModel<NotificationMessage>(
            ix.Ascending(x => x.UserId).Ascending(x => x.Status),
            new CreateIndexOptions { Name = "IX_UserId_Status" });

        // History: tất cả thông báo của user, mới nhất trước
        var userCreatedIndex = new CreateIndexModel<NotificationMessage>(
            ix.Ascending(x => x.UserId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_UserId_CreatedAt_Desc" });

        // Background job: tìm các notification đã scheduled chờ gửi
        var pendingScheduledIndex = new CreateIndexModel<NotificationMessage>(
            ix.Ascending(x => x.Status).Ascending(x => x.ScheduledFor),
            new CreateIndexOptions { Name = "IX_Status_ScheduledFor" });

        await collection.Indexes.CreateManyAsync(
        [
            userStatusIndex,
            userCreatedIndex,
            pendingScheduledIndex
        ]);
    }

    private static async Task ConfigureNotificationTemplateIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<NotificationTemplate>("NotificationTemplates");
        var ix = Builders<NotificationTemplate>.IndexKeys;

        // Lookup template theo code (e.g. "WORKOUT_REMINDER", "AI_COACH_TIP")
        var codeIndex = new CreateIndexModel<NotificationTemplate>(
            ix.Ascending(x => x.TemplateCode),
            new CreateIndexOptions { Unique = true, Name = "UIX_TemplateCode" });

        // Lọc template đang active theo channel (Push, Email, SMS)
        var channelActiveIndex = new CreateIndexModel<NotificationTemplate>(
            ix.Ascending(x => x.Channel).Ascending(x => x.IsActive),
            new CreateIndexOptions { Name = "IX_Channel_IsActive" });

        await collection.Indexes.CreateManyAsync([codeIndex, channelActiveIndex]);
    }
}
