using System.Net.Http.Json;
using System.Text.Json;
using Notification.Application.Clients;
using Notification.Application.Common;
using Notification.Application.DTOs.SmartPush;

namespace Notification.Infrastructure.Clients;

public class NutritionActivityClient : INutritionActivityClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private sealed class NutritionSummaryPayload
    {
        public Guid UserId { get; set; }
        public int TargetCalories { get; set; }
        public int ConsumedCalories { get; set; }
        public int WaterIntakeMl { get; set; }
        public int MealsLoggedCount { get; set; }
    }

    public NutritionActivityClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<TodayNutritionSignalDto?> GetTodaySummaryAsync(
        Guid userId,
        string timeZoneId,
        CancellationToken cancellationToken)
    {
        var url =
            $"/api/internal/nutrition/daily-summary/{userId}?timeZoneId={Uri.EscapeDataString(timeZoneId)}";
        var response = await _httpClient.GetAsync(url, cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return null;
        response.EnsureSuccessStatusCode();

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<NutritionSummaryPayload>>(JsonOpts, cancellationToken);
        var data = api?.Data;
        if (api is not { Success: true } || data is null)
            return null;

        var targetCal = Math.Max(1, data.TargetCalories);
        var remainingPct = (int)Math.Clamp(
            Math.Round(100.0 * (targetCal - data.ConsumedCalories) / targetCal),
            0, 100);
        // No water target from Nutrition — use 2000ml conventional goal for % only.
        const int waterGoalMl = 2000;
        var waterPct = (int)Math.Clamp(Math.Round(100.0 * data.WaterIntakeMl / waterGoalMl), 0, 200);

        return new TodayNutritionSignalDto(
            userId,
            data.MealsLoggedCount,
            remainingPct,
            waterPct,
            null);
    }
}
