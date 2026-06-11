namespace Iam.Application.DTOs;

public sealed record DueSmartPushUserDto(
    Guid UserId,
    TimeSpan PreferredReminderTime,
    string TimeZoneId,
    string MotivationStyle
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
    string SubscriptionTier = "Free"
);
