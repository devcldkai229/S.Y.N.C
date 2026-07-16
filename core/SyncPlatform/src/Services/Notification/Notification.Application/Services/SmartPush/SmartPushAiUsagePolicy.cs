using Microsoft.Extensions.Options;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;

namespace Notification.Application.Services.SmartPush;

public class SmartPushAiUsagePolicy : ISmartPushAiUsagePolicy
{
    private readonly SmartPushOptions _options;

    public SmartPushAiUsagePolicy(IOptions<SmartPushOptions> options) => _options = options.Value;

    public bool ShouldUseAi(SmartPushContextDto context, SmartPushDecision decision)
    {
        if (!_options.UseAiGeneration)
            return false;

        // Prefer AI for high-care / personalized triggers; Free tier still gets templates unless risky.
        if (decision.TriggerType is "BurnoutRecovery" or "ChurnReengage" or "TodayWorkoutReminder" or "NutritionNudge")
            return true;

        if (context.BurnoutRiskScore >= 70 || context.CurrentStreak >= 7)
            return true;

        if (!string.IsNullOrEmpty(context.SubscriptionTier) &&
            (context.SubscriptionTier.Equals("Premium", StringComparison.OrdinalIgnoreCase) ||
             context.SubscriptionTier.Equals("Pro", StringComparison.OrdinalIgnoreCase)))
            return true;

        return false;
    }
}
