namespace Iam.Application.DTOs;

public sealed record DueSmartPushUserDto(
    Guid UserId,
    TimeSpan PreferredReminderTime,
    string TimeZoneId,
    string MotivationStyle
);

public sealed record SmartPushEnabledUserDto(
    Guid UserId,
    string TimeZoneId,
    TimeSpan? PreferredReminderTime,
    string? PeakEnergyTimeWindow,
    DateTimeOffset? LastActiveAt,
    bool SmartPushEnabled,
    bool AllowAiGeneratedNotification
);

public sealed record IamSmartPushContextDto(
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
    string SubscriptionTier = "Free",
    int RecoveryScore = 100,
    int ChurnRiskScore = 0,
    string? PeakEnergyTimeWindow = null,
    DateTimeOffset? LastActiveAt = null,
    TimeSpan? PreferredReminderTime = null
);
