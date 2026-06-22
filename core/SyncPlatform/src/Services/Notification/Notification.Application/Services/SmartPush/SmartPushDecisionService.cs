using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushDecisionService : ISmartPushDecisionService
{
    public SmartPushDecision Decide(SmartPushContextDto context, string topic)
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

        // 2. Evaluate by topic
        return topic.ToLowerInvariant() switch
        {
            "streak" => EvaluateStreak(context),
            "exercise" => EvaluateExercise(context),
            "nutrition" => EvaluateNutrition(context),
            _ => SmartPushDecision.Skip($"Unknown topic: '{topic}'")
        };
    }

    private static SmartPushDecision EvaluateStreak(SmartPushContextDto context)
    {
        // StreakProtectionReminder: Current streak is at least 3, and they haven't completed their workout today
        if (context.CurrentStreak >= 3 && !context.CompletedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "StreakProtectionReminder", 
                $"Protect current streak of {context.CurrentStreak} days.");
        }

        // StreakCelebrateReminder: Completed workout today, let's congratulate them and keep it going tomorrow
        if (context.CompletedWorkoutToday && context.CurrentStreak >= 1)
        {
            return SmartPushDecision.Send(
                "StreakCelebrateReminder",
                $"Celebrate streak of {context.CurrentStreak} days.");
        }

        // StreakEncourageReminder: If they didn't complete workout today (missed workout), encourage them to get back tomorrow
        if (!context.CompletedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "StreakEncourageReminder",
                "Encourage user to start or resume streak tomorrow.");
        }

        return SmartPushDecision.Skip("No streak rules matched.");
    }

    private static SmartPushDecision EvaluateExercise(SmartPushContextDto context)
    {
        // RecoveryGentleReminder: High burnout risk score
        if (context.BurnoutRiskScore >= 85)
        {
            return SmartPushDecision.Send(
                "RecoveryGentleReminder",
                $"High burnout risk score ({context.BurnoutRiskScore}). Recommend gentle recovery.");
        }

        // FinishWorkoutReminder: Started but not completed today's workout
        if (context.HasStartedWorkoutToday && !context.CompletedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "FinishWorkoutReminder",
                $"Workout started but not completed ({context.CompletionRate}% completion rate).");
        }

        // TomorrowWorkoutPreview: Tomorrow has a workout scheduled
        if (context.HasWorkoutScheduledTomorrow)
        {
            return SmartPushDecision.Send(
                "TomorrowWorkoutPreview",
                $"Preview scheduled tomorrow workout '{context.TomorrowWorkoutName}'.");
        }

        // TodayWorkoutSummary: Completed workout today, summarize stats
        if (context.CompletedWorkoutToday)
        {
            return SmartPushDecision.Send(
                "TodayWorkoutSummary",
                "Summarize today's completed workout stats.");
        }

        return SmartPushDecision.Skip("No exercise rules matched.");
    }

    private static SmartPushDecision EvaluateNutrition(SmartPushContextDto context)
    {
        // NutritionWaterReminder: Low water intake today
        if (context.NutritionWaterIntakeMl < 1500)
        {
            return SmartPushDecision.Send(
                "NutritionWaterReminder",
                $"Low water intake today ({context.NutritionWaterIntakeMl} ml).");
        }

        // NutritionProteinReminder: Consumed protein below target by more than 20%
        if (context.NutritionTargetProtein > 0 && context.NutritionConsumedProtein < context.NutritionTargetProtein * 0.8m)
        {
            return SmartPushDecision.Send(
                "NutritionProteinReminder",
                $"Protein target under-compliance ({context.NutritionConsumedProtein}g consumed vs {context.NutritionTargetProtein}g target).");
        }

        // NutritionCalorieUnder: Calorie intake below target by more than 20%
        if (context.NutritionTargetCalories > 0 && context.NutritionConsumedCalories < context.NutritionTargetCalories * 0.8)
        {
            return SmartPushDecision.Send(
                "NutritionCalorieUnder",
                $"Calorie intake under-compliance ({context.NutritionConsumedCalories} kcal consumed vs {context.NutritionTargetCalories} kcal target).");
        }

        // NutritionLogMeals: Logged less than 2 meals today
        if (context.NutritionMealsLoggedCount < 2)
        {
            return SmartPushDecision.Send(
                "NutritionLogMeals",
                $"Logged only {context.NutritionMealsLoggedCount} meals today.");
        }

        return SmartPushDecision.Skip("No nutrition rules matched.");
    }
}
