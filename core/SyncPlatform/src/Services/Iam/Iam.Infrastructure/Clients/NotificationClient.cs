using System.Net.Http.Json;
using Iam.Application.Abstractions;

namespace Iam.Infrastructure.Clients;

public sealed class NotificationClient : INotificationClient
{
    private readonly HttpClient _http;

    public NotificationClient(HttpClient http) => _http = http;

    public async Task SendAchievementUnlockedAsync(
        Guid userId,
        string achievementName,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _http.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId,
                    type = "RewardMinted",
                    channel = "InApp",
                    priority = "Normal",
                    title = "🏆 Achievement Unlocked!",
                    body = $"Bạn vừa mở khóa thành tích: {achievementName}",
                    deepLink = "/achievements",
                },
                cancellationToken);
        }
        catch
        {
            // Notification is best-effort — never fail the caller
        }
    }
}
