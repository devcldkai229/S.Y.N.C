using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushAiUsagePolicy : ISmartPushAiUsagePolicy
{
    public bool ShouldUseAi(SmartPushContextDto context, SmartPushDecision decision)
    {
        // 1. TriggerType is RecoveryGentleReminder
        if (decision.TriggerType == "RecoveryGentleReminder")
        {
            return true;
        }

        // 2. High burnout risk
        if (context.BurnoutRiskScore >= 80)
        {
            return true;
        }

        // 3. High current streak
        if (context.CurrentStreak >= 7)
        {
            return true;
        }

        // 4. User tier is Premium or Pro
        if (!string.IsNullOrEmpty(context.SubscriptionTier) &&
            (context.SubscriptionTier.Equals("Premium", StringComparison.OrdinalIgnoreCase) ||
             context.SubscriptionTier.Equals("Pro", StringComparison.OrdinalIgnoreCase)))
        {
            return true;
        }

        // 5. Unfinished workout reminder with low-to-medium progress
        if (decision.TriggerType == "FinishWorkoutReminder" &&
            context.HasStartedWorkoutToday &&
            context.CompletionRate > 0 &&
            context.CompletionRate < 60)
        {
            return true;
        }

        // Default to false for low-personalization cases
        return false;
    }
}
