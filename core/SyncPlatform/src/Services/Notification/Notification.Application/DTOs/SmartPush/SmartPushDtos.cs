namespace Notification.Application.DTOs.SmartPush;

public record DueSmartPushUserDto(
    Guid UserId,
    TimeSpan PreferredReminderTime,
    string TimeZoneId = "Asia/Ho_Chi_Minh",
    string MotivationStyle = "Gentle"
);

public record SmartPushEnabledUserDto(
    Guid UserId,
    string TimeZoneId,
    TimeSpan? PreferredReminderTime,
    string? PeakEnergyTimeWindow,
    DateTimeOffset? LastActiveAt,
    bool SmartPushEnabled,
    bool AllowAiGeneratedNotification
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
    string? SubscriptionTier = null,
    int RecoveryScore = 100,
    int ChurnRiskScore = 0,
    string? PeakEnergyTimeWindow = null,
    DateTimeOffset? LastActiveAt = null,
    TimeSpan? PreferredReminderTime = null,
    int? DaysSinceLastWeighIn = null
);

public record TodayWorkoutActivityDto(
    Guid UserId,
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
    string WorkoutSource = "none", // roadmap | custom | both | none
    string? TodayWorkoutType = null,
    string? ScheduledLocalTime = null,
    int MissedRecentCount = 0
);

public record TodayNutritionSignalDto(
    Guid UserId,
    int MealsLoggedToday,
    int RemainingCaloriesPct,
    int WaterPct,
    DateTimeOffset? LastMealLoggedAt
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
    string? SubscriptionTier = null,
    int RecoveryScore = 100,
    int ChurnRiskScore = 0,
    string? PeakEnergyTimeWindow = null,
    DateTimeOffset? LastActiveAt = null,
    TimeSpan? PreferredReminderTime = null,
    string WorkoutSource = "none",
    string? TodayWorkoutType = null,
    string? ScheduledLocalTime = null,
    int MissedRecentCount = 0,
    int MealsLoggedToday = 0,
    int RemainingCaloriesPct = 100,
    int WaterPct = 100,
    DateTimeOffset? LastMealLoggedAt = null,
    DateTime UtcNow = default,
    DateOnly LocalDate = default,
    int? DaysSinceLastWeighIn = null
);

public record GeneratedPushMessageDto(
    string Title,
    string Body,
    string DeepLink = "sync://workout/today"
);
