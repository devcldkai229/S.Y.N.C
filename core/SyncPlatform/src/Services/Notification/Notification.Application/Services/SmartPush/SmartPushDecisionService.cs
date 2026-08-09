using Microsoft.Extensions.Options;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;

namespace Notification.Application.Services.SmartPush;

public class SmartPushDecisionService : ISmartPushDecisionService
{
    private readonly SmartPushOptions _options;
    private readonly ISmartPushScheduleRepository _repo;

    public SmartPushDecisionService(IOptions<SmartPushOptions> options, ISmartPushScheduleRepository repo)
    {
        _options = options.Value;
        _repo = repo;
    }

    public async Task<SmartPushDecision> DecideAsync(SmartPushContextDto context, CancellationToken ct)
    {
        if (!context.SmartPushEnabled)
            return SmartPushDecision.Skip("Smart push is disabled for the user.");
        if (!context.AllowAiGeneratedNotification)
            return SmartPushDecision.Skip("AI generated notifications are disabled for the user.");

        var localDate = context.LocalDate == default
            ? DateOnly.FromDateTime(DateTime.UtcNow)
            : context.LocalDate;
        var localTime = ResolveLocalTimeOfDay(context);
        var isAfternoonOrEvening = localTime >= new TimeSpan(15, 0, 0);

        async Task<SmartPushDecision?> Try(string trigger, bool condition, string reason)
        {
            if (!condition) return null;
            if (await IsOnCooldownAsync(context.UserId, trigger, ct)) return null;
            var dedup = $"{context.UserId:D}:{localDate:yyyy-MM-dd}:{trigger}";
            if (await _repo.HasDedupKeyAsync(dedup, ct)) return null;
            return SmartPushDecision.Send(trigger, reason);
        }

        return
            await Try("TodayWorkoutReminder",
                context.HasWorkoutScheduledToday && !context.CompletedWorkoutToday,
                "Có buổi tập hôm nay chưa hoàn thành.")
            ?? await Try("WeighInReminder",
                context.DaysSinceLastWeighIn is null or > 7,
                context.DaysSinceLastWeighIn is null
                    ? "Chưa có lịch sử cân — nhắc weigh-in."
                    : $"Đã {context.DaysSinceLastWeighIn} ngày chưa cân.")
            ?? await Try("StreakProtection",
                context.CurrentStreak >= 3 && !context.HasStartedWorkoutToday && isAfternoonOrEvening,
                $"Streak {context.CurrentStreak}, chưa hoạt động hôm nay.")
            ?? await Try("MissedWorkouts",
                context.MissedRecentCount >= 1,
                $"Bỏ lỡ {context.MissedRecentCount} buổi gần đây.")
            ?? await Try("BurnoutRecovery",
                context.BurnoutRiskScore >= 70 || context.RecoveryScore <= 40,
                $"Burnout={context.BurnoutRiskScore}, Recovery={context.RecoveryScore}.")
            ?? await Try("NutritionNudge",
                (context.MealsLoggedToday == 0 && localTime >= new TimeSpan(12, 0, 0))
                || (context.RemainingCaloriesPct >= 50 && localTime >= new TimeSpan(17, 0, 0))
                || context.WaterPct < 40,
                "Nhắc dinh dưỡng theo dữ liệu hôm nay.")
            ?? await Try("ChurnReengage",
                context.ChurnRiskScore >= 70
                || (context.LastActiveAt is { } last && (context.UtcNow - last).TotalDays >= 3),
                "Rủi ro churn / lâu không mở app.")
            ?? await Try("ProgressCelebrate",
                context.CompletedWorkoutToday || context.RemainingCaloriesPct <= 10,
                "Chúc mừng tiến bộ hôm nay.")
            ?? await Try("GentleCheckIn",
                !context.HasStartedWorkoutToday && context.MissedRecentCount == 0,
                "Check-in nhẹ khi im ắng.")
            ?? SmartPushDecision.Skip("No notification rules matched today's signals.");
    }

    private async Task<bool> IsOnCooldownAsync(Guid userId, string trigger, CancellationToken ct)
    {
        if (!_options.TriggerCooldownDays.TryGetValue(trigger, out var days) || days <= 0)
            return false;
        var last = await _repo.GetLastTriggerSentAtAsync(userId, trigger, ct);
        if (last is null) return false;
        return (DateTimeOffset.UtcNow - last.Value).TotalDays < days;
    }

    private static TimeSpan ResolveLocalTimeOfDay(SmartPushContextDto context)
    {
        try
        {
            var tz = TimeZoneInfo.FindSystemTimeZoneById(
                string.IsNullOrWhiteSpace(context.TimeZoneId) ? "Asia/Ho_Chi_Minh" : context.TimeZoneId);
            var utc = context.UtcNow == default
                ? DateTimeOffset.UtcNow
                : new DateTimeOffset(DateTime.SpecifyKind(context.UtcNow, DateTimeKind.Utc));
            return TimeZoneInfo.ConvertTime(utc, tz).TimeOfDay;
        }
        catch
        {
            return DateTimeOffset.UtcNow.TimeOfDay;
        }
    }
}
