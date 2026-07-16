using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Clients;

public interface INutritionActivityClient
{
    Task<TodayNutritionSignalDto?> GetTodaySummaryAsync(
        Guid userId,
        string timeZoneId,
        CancellationToken cancellationToken);
}
