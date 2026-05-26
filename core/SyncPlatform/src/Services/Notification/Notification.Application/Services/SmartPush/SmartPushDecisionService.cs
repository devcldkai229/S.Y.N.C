using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushDecisionService : ISmartPushDecisionService
{
    public SmartPushDecision Decide(SmartPushContextDto context)
    {
        // 1. Core preferences checks
        if (!context.SmartPushEnabled)
        {
            return SmartPushDecision.Skip("Smart push is disabled for the user.");
        }

        if (!context.AllowAiGeneratedNotification)
        {
            return SmartPushDecision.Skip("AI generated notifications are disabled for the user.");
        }

        // 2. Already completed workout checks
        if (context.CompletedWorkoutToday)
        {
            return SmartPushDecision.Skip("Workout is already completed today.");
        }

        // 3. RecoveryGentleReminder Rule
        if (context.BurnoutRiskScore >= 85)
        {
            return SmartPushDecision.Send(
                "RecoveryGentleReminder", 
                $"Burnout risk score is high ({context.BurnoutRiskScore}).");
        }

        // 4. FinishWorkoutReminder Rule
        if (context.HasStartedWorkoutToday && context.CompletionRate < 80)
        {
            return SmartPushDecision.Send(
                "FinishWorkoutReminder", 
                $"Workout started but not completed (Completion rate: {context.CompletionRate}%).");
        }

        // 5. StreakProtectionReminder Rule
        if (context.CurrentStreak >= 3 && !context.HasStartedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "StreakProtectionReminder", 
                $"Current streak is {context.CurrentStreak} and workout is not started yet.");
        }

        // 6. ScheduledWorkoutReminder Rule
        if (context.HasWorkoutScheduledToday && !context.HasStartedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "ScheduledWorkoutReminder", 
                "Workout is scheduled today but not started yet.");
        }

        return SmartPushDecision.Skip("No notification rules matched user's activity context today.");
    }
}
