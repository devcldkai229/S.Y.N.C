namespace Notification.Application.DTOs.SmartPush;

public record DueSmartPushUserDto(
    Guid UserId,
    TimeSpan PreferredReminderTime,
    string TimeZoneId = "Asia/Ho_Chi_Minh",
    string MotivationStyle = "Gentle"
);

public record IamSmartPushContextDto(
    Guid UserId,
    string FullName,
    int BurnoutRiskScore,
    int CurrentStreak,
    int LongestStreak,
    int CurrentLevel,
    long CurrentXP,
    string MotivationStyle,
    string FitnessGoal,
    string ActivityLevel,
    string FitnessExperienceLevel,
    string WorkoutLocationPreference,
    bool SmartPushEnabled,
    bool AllowAiGeneratedNotification,
    string TimeZoneId,
    string AgentPersona = "FriendlyBuddy",
    string? SubscriptionTier = null
);

public record TodayWorkoutActivityDto(
    Guid UserId,
    bool HasWorkoutScheduledToday,
    Guid? SessionId,
    string? TodayWorkoutName,
    bool HasStartedWorkoutToday,
    bool CompletedWorkoutToday,
    DateTimeOffset? LatestStartedAt,
    DateTimeOffset? LatestCompletedAt,
    int ActualDurationMinutes,
    int CompletionRate,
    int PerceivedDifficulty,
    int EnergyLevelBefore,
    int EnergyLevelAfter,
    int CaloriesBurned,
    int SkippedExercisesCount,
    int CompletedSetsCount,
    int TotalLoggedSetsCount,
    bool HasWorkoutScheduledTomorrow,
    string? TomorrowWorkoutName,
    List<string> TomorrowExerciseNames,
    string? TodayWorkoutAiCoachFeedback,
    string? TodayWorkoutSessionFeedback
);

public record TodayNutritionDto(
    Guid UserId,
    DateOnly Date,
    int TargetCalories,
    int ConsumedCalories,
    decimal TargetProteinGram,
    decimal ConsumedProteinGram,
    decimal TargetCarbGram,
    decimal ConsumedCarbGram,
    decimal TargetFatGram,
    decimal ConsumedFatGram,
    int WaterIntakeMl,
    int MealsLoggedCount
);

public record SmartPushContextDto(
    Guid UserId,
    string FullName,
    int BurnoutRiskScore,
    int CurrentStreak,
    int LongestStreak,
    int CurrentLevel,
    long CurrentXP,
    string MotivationStyle,
    string FitnessGoal,
    string ActivityLevel,
    string FitnessExperienceLevel,
    string WorkoutLocationPreference,
    bool SmartPushEnabled,
    bool AllowAiGeneratedNotification,
    string TimeZoneId,
    string AgentPersona,
    bool HasWorkoutScheduledToday,
    string? TodayWorkoutName,
    bool HasStartedWorkoutToday,
    bool CompletedWorkoutToday,
    DateTimeOffset? LatestStartedAt,
    DateTimeOffset? LatestCompletedAt,
    int ActualDurationMinutes,
    int CompletionRate,
    int PerceivedDifficulty,
    int EnergyLevelBefore,
    int EnergyLevelAfter,
    int CaloriesBurned,
    int SkippedExercisesCount,
    string? SubscriptionTier,
    bool HasWorkoutScheduledTomorrow,
    string? TomorrowWorkoutName,
    List<string> TomorrowExerciseNames,
    string? TodayWorkoutAiCoachFeedback,
    string? TodayWorkoutSessionFeedback,
    int NutritionTargetCalories,
    int NutritionConsumedCalories,
    decimal NutritionTargetProtein,
    decimal NutritionConsumedProtein,
    decimal NutritionTargetCarbs,
    decimal NutritionConsumedCarbs,
    decimal NutritionTargetFat,
    decimal NutritionConsumedFat,
    int NutritionWaterIntakeMl,
    int NutritionMealsLoggedCount
);

public record GeneratedPushMessageDto(
    string Title,
    string Body,
    string DeepLink = "sync://workout/today"
);
