using Notification.Application.DTOs;
using Notification.Application.Common;

namespace Notification.Application.Services;

public interface INotificationService
{
    Task<(IReadOnlyList<NotificationMessageDto> Items, PaginationMetadata Pagination)> GetPagedByUserIdAsync(
        Guid userId, 
        NotificationSearchRequest request, 
        CancellationToken cancellationToken = default);

    Task<int> GetUnreadCountByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    Task MarkAsReadAsync(Guid userId, Guid messageId, CancellationToken cancellationToken = default);

    Task MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken = default);

    Task DeleteNotificationAsync(Guid userId, Guid messageId, CancellationToken cancellationToken = default);

    Task<NotificationMessageDto> SendNotificationAsync(SendNotificationDto dto, CancellationToken cancellationToken = default);

    Task<NotificationMessageDto> SendTemplatedNotificationAsync(SendTemplatedNotificationDto dto, CancellationToken cancellationToken = default);

    Task CancelScheduledNotificationAsync(Guid messageId, CancellationToken cancellationToken = default);
}
