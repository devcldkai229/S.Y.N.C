using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Clients;

public interface INutritionClient
{
    Task<TodayNutritionDto?> GetTodayNutritionAsync(Guid userId, string? userLocalDate, CancellationToken cancellationToken);
}
