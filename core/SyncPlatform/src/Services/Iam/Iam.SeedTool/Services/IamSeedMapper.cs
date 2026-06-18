using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.SeedTool.Models;

namespace Iam.SeedTool.Services;

public static class IamSeedMapper
{
    public static User MapUser(UserSeedDto dto, string avatarUrl)
    {
        return new User
        {
            Id = dto.Id,
            Email = dto.Email,
            PhoneNumber = dto.PhoneNumber,
            PasswordHash = dto.PasswordHash,
            FullName = dto.FullName,
            AvatarUrl = avatarUrl,
            BackgroundImageUrl = null,
            Role = ParseEnum<UserRole>(dto.Role),
            Status = ParseEnum<UserStatus>(dto.Status),
            SubscriptionTier = ParseEnum<SubscriptionTier>(dto.SubscriptionTier),
            EmailVerified = dto.EmailVerified,
            EmailVerificationToken = dto.EmailVerificationToken,
            PasswordResetToken = dto.PasswordResetToken,
            PasswordResetTokenExpiresAt = dto.PasswordResetTokenExpiresAt,
            PhoneVerified = dto.PhoneVerified,
            PreferredLanguage = dto.PreferredLanguage,
            TimeZone = dto.TimeZone,
            LastLoginAt = dto.LastLoginAt,
            LastActiveAt = dto.LastActiveAt,
            CreatedAt = dto.CreatedAt,
            UpdatedAt = dto.UpdatedAt,
            DeletedAt = dto.DeletedAt,
        };
    }

    public static BiometricProfile MapBiometric(BiometricProfileSeedDto dto) => new()
    {
        Id = dto.Id,
        UserId = dto.UserId,
        Gender = ParseEnum<Gender>(dto.Gender),
        DateOfBirth = dto.DateOfBirth,
        HeightCm = dto.HeightCm,
        CurrentWeightKg = dto.CurrentWeightKg,
        TargetWeightKg = dto.TargetWeightKg,
        CurrentBodyFatPercentage = dto.CurrentBodyFatPercentage,
        GoalBodyFatPercentage = dto.GoalBodyFatPercentage,
        MuscleMassKg = dto.MuscleMassKg,
        FitnessGoal = ParseEnum<FitnessGoal>(dto.FitnessGoal),
        ActivityLevel = ParseEnum<ActivityLevel>(dto.ActivityLevel),
        FitnessExperienceLevel = ParseEnum<FitnessExperienceLevel>(dto.FitnessExperienceLevel),
        WorkoutLocationPreference = ParseEnum<WorkoutLocationPreference>(dto.WorkoutLocationPreference),
        BaseTDEE = dto.BaseTDEE,
        BMR = dto.BMR,
        DailyProteinTargetGram = dto.DailyProteinTargetGram,
        DailyCarbTargetGram = dto.DailyCarbTargetGram,
        DailyFatTargetGram = dto.DailyFatTargetGram,
        Injuries = dto.Injuries,
        Medications = dto.Medications,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        DeletedAt = dto.DeletedAt,
    };

    public static UserPreference MapPreference(UserPreferenceSeedDto dto) => new()
    {
        Id = dto.Id,
        UserId = dto.UserId,
        Allergies = dto.Allergies?.Select(a => new AllergyItem(a.AllergenName, a.Severity, a.Notes)).ToList(),
        FavoriteFoods = dto.FavoriteFoods,
        DislikedFoods = dto.DislikedFoods,
        AgentPersona = ParseEnum<AgentPersona>(dto.AgentPersona),
        MotivationStyle = ParseEnum<MotivationStyle>(dto.MotivationStyle),
        AutoOrderEnabled = dto.AutoOrderEnabled,
        MaxAutoOrderLimitDaily = dto.MaxAutoOrderLimitDaily,
        MaxAutoOrderLimitPerOrder = dto.MaxAutoOrderLimitPerOrder,
        DataSharingConsent = dto.DataSharingConsent,
        MarketingConsent = dto.MarketingConsent,
        SmartPushEnabled = dto.SmartPushEnabled,
        AllowAiGeneratedNotification = dto.AllowAiGeneratedNotification,
        PreferredReminderTime = ParseTimeSpan(dto.PreferredReminderTime),
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        DeletedAt = dto.DeletedAt,
    };

    public static GamificationProfile MapGamification(GamificationProfileSeedDto dto) => new()
    {
        Id = dto.Id,
        UserId = dto.UserId,
        CurrentLevel = dto.CurrentLevel,
        CurrentXP = dto.CurrentXP,
        CurrentStreak = dto.CurrentStreak,
        LongestStreak = dto.LongestStreak,
        SyncCoins = dto.SyncCoins,
        AchievementPoints = dto.AchievementPoints,
        ConsecutivePerfectDays = dto.ConsecutivePerfectDays,
        LastActivityDate = dto.LastActivityDate,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        DeletedAt = dto.DeletedAt,
    };

    public static UserAchievement MapUserAchievement(UserAchievementSeedDto dto) => new()
    {
        Id = dto.Id,
        UserId = dto.UserId,
        AchievementId = dto.AchievementId,
        UnlockedAt = dto.UnlockedAt,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        DeletedAt = dto.DeletedAt,
    };

    public static Achievement MapAchievement(AchievementSeedDto dto, string iconUrl) => new()
    {
        Id = dto.Id,
        Code = dto.Code,
        Name = dto.Name,
        Description = dto.Description,
        XPReward = dto.XpReward,
        CoinReward = dto.CoinReward,
        IconUrl = iconUrl,
        RequirementJson = dto.RequirementJson,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        DeletedAt = dto.DeletedAt,
    };

    public static string AchievementAssetPath(string code)
        => $"achievements/{code.ToLowerInvariant().Replace('_', '-')}.png";

    private static TimeSpan? ParseTimeSpan(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        return TimeSpan.TryParse(value, out var ts) ? ts : null;
    }

    private static TEnum ParseEnum<TEnum>(string value) where TEnum : struct, Enum
    {
        if (Enum.TryParse<TEnum>(value, ignoreCase: true, out var parsed))
            return parsed;

        throw new ArgumentException($"Unknown {typeof(TEnum).Name} value: '{value}'");
    }
}
