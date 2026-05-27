using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Clients;

public interface IRoadmapActivityClient
{
    Task<TodayWorkoutActivityDto?> GetTodayActivityAsync(Guid userId, string timeZoneId, CancellationToken cancellationToken);
}
