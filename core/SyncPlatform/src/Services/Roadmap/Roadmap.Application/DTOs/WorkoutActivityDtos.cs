namespace Roadmap.Application.DTOs;

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
    string WorkoutSource = "none",
    string? TodayWorkoutType = null,
    string? ScheduledLocalTime = null,
    int MissedRecentCount = 0
);
