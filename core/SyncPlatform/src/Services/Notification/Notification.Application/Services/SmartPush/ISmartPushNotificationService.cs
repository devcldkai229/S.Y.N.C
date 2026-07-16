namespace Notification.Application.Services.SmartPush;

public interface ISmartPushNotificationService
{
    Task ProcessDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken);
    Task SeedUserScheduleAsync(Guid userId, CancellationToken cancellationToken);
    Task ProcessUserNowAsync(Guid userId, CancellationToken cancellationToken);
    Task NightlyRecomputeAsync(CancellationToken cancellationToken);
}
