using Notification.Domain.Models;
using Notification.Domain.Enums;

namespace Notification.Domain.Repositories;

public interface INotificationMessageRepository : IGenericRepository<NotificationMessage>
{
    Task<(IReadOnlyList<NotificationMessage> Items, int TotalRecords)> GetPagedByUserIdAsync(
        Guid userId, 
        int pageNumber, 
        int pageSize, 
        NotificationStatus? status = null, 
        CancellationToken cancellationToken = default);

    Task<int> GetUnreadCountByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    Task MarkAllAsReadByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<bool> HasSmartPushSentTodayAsync(
        Guid userId,
        DateTimeOffset utcNow,
        string timeZoneId,
        CancellationToken cancellationToken);
}
