using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushDeepLinkResolver : ISmartPushDeepLinkResolver
{
    private static readonly HashSet<string> WhitelistedDeepLinks = new()
    {
        "sync://workout/today",
        "sync://roadmap/current",
        "sync://recovery/today",
        "sync://profile/progress",
        "sync://nutrition/today",
        "sync://workout/tomorrow"
    };

    public string ResolveDeepLink(SmartPushContextDto context, SmartPushDecision decision)
    {
        // 1. Highest priority: Burnout >= 85
        if (context.BurnoutRiskScore >= 85)
        {
            return "sync://recovery/today";
        }

        // 2. Started but not completed workout today
        if (context.HasStartedWorkoutToday && !context.CompletedWorkoutToday)
        {
            return "sync://workout/today";
        }

        // 3. Resolve by TriggerType
        var targetLink = decision.TriggerType switch
        {
            "RecoveryGentleReminder" => "sync://recovery/today",
            "FinishWorkoutReminder" => "sync://workout/today",
            "ScheduledWorkoutReminder" => "sync://workout/today",
            "StreakProtectionReminder" => "sync://workout/today",
            "StreakCelebrateReminder" => "sync://profile/progress",
            "StreakEncourageReminder" => "sync://workout/today",
            "TomorrowWorkoutPreview" => "sync://workout/tomorrow",
            "TodayWorkoutSummary" => "sync://profile/progress",
            var trigger when trigger.StartsWith("Nutrition", StringComparison.OrdinalIgnoreCase) => "sync://nutrition/today",
            "ProgressEncouragement" => "sync://profile/progress",
            _ => "sync://roadmap/current"
        };

        // Whitelist validation
        return WhitelistedDeepLinks.Contains(targetLink) ? targetLink : "sync://roadmap/current";
    }
}
