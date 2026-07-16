using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushDeepLinkResolver : ISmartPushDeepLinkResolver
{
    private static readonly HashSet<string> Whitelisted = new(StringComparer.Ordinal)
    {
        "sync://workout/today",
        "sync://roadmap/current",
        "sync://recovery/today",
        "sync://profile/progress",
        "sync://nutrition/today"
    };

    public string ResolveDeepLink(SmartPushContextDto context, SmartPushDecision decision)
    {
        var link = decision.TriggerType switch
        {
            "BurnoutRecovery" or "RecoveryGentleReminder" => "sync://recovery/today",
            "NutritionNudge" => "sync://nutrition/today",
            "ProgressCelebrate" => "sync://profile/progress",
            "ChurnReengage" or "GentleCheckIn" => "sync://roadmap/current",
            _ => "sync://workout/today"
        };
        return Whitelisted.Contains(link) ? link : "sync://roadmap/current";
    }
}
