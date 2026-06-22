namespace Notification.Application.Services.SmartPush;

public interface ISmartPushNotificationService
{
    Task ProcessDueUsersAsync(
        DateTime utcNow, 
        Guid? targetUserId = null, 
        bool sendImmediately = false, 
        CancellationToken cancellationToken = default);
}
