namespace Notification.Application.Services.SmartPush;

public interface ISmartPushNotificationService
{
    Task ProcessDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken);
}
