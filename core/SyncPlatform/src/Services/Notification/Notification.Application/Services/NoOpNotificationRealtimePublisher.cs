using Notification.Application.DTOs;

namespace Notification.Application.Services;

public sealed class NoOpNotificationRealtimePublisher : INotificationRealtimePublisher
{
    public Task PublishToUserAsync(
        Guid userId,
        NotificationMessageDto notification,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
