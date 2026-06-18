using Notification.Application.DTOs;

namespace Notification.Application.Services;

/// <summary>
/// Pushes newly created in-app notifications to connected clients (SignalR).
/// </summary>
public interface INotificationRealtimePublisher
{
    Task PublishToUserAsync(
        Guid userId,
        NotificationMessageDto notification,
        CancellationToken cancellationToken = default);
}
