using Microsoft.AspNetCore.SignalR;
using Notification.API.Hubs;
using Notification.Application.DTOs;
using Notification.Application.Services;

namespace Notification.API.Services;

public sealed class SignalRNotificationRealtimePublisher : INotificationRealtimePublisher
{
    private readonly IHubContext<NotificationHub> _hub;

    public SignalRNotificationRealtimePublisher(IHubContext<NotificationHub> hub) => _hub = hub;

    public Task PublishToUserAsync(
        Guid userId,
        NotificationMessageDto notification,
        CancellationToken cancellationToken = default) =>
        _hub.Clients
            .Group(NotificationHub.UserGroup(userId))
            .SendAsync(NotificationHub.ReceivedEvent, notification, cancellationToken);
}
