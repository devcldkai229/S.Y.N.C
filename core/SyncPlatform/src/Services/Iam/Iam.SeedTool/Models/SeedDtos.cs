using System.Text.Json.Serialization;

namespace Iam.SeedTool.Models;

public sealed class IamUsersSeedFile
{
    public List<UserSeedDto> Users { get; set; } = [];

    public List<BiometricProfileSeedDto> BiometricProfiles { get; set; } = [];

    public List<UserPreferenceSeedDto> UserPreferences { get; set; } = [];

    public List<GamificationProfileSeedDto> GamificationProfiles { get; set; } = [];

    public List<UserAchievementSeedDto> UserAchievements { get; set; } = [];
}

public sealed class IamAchievementsSeedFile
{
    public List<AchievementSeedDto> Achievements { get; set; } = [];
}

public sealed class UserSeedDto
{
    public Guid Id { get; set; }

    public string Email { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }

    public string PasswordHash { get; set; } = string.Empty;

    public string FullName { get; set; } = string.Empty;

    [JsonIgnore]
    public string? AvatarUrl { get; set; }

    public string? BackgroundImageUrl { get; set; }

    public string Role { get; set; } = "User";

    public string Status { get; set; } = "Active";

    public string SubscriptionTier { get; set; } = "Free";

    public bool EmailVerified { get; set; }

    public string? EmailVerificationToken { get; set; }

    public string? PasswordResetToken { get; set; }

    public DateTimeOffset? PasswordResetTokenExpiresAt { get; set; }

    public bool PhoneVerified { get; set; }

    public string PreferredLanguage { get; set; } = "vi";

    public string TimeZone { get; set; } = "Asia/Ho_Chi_Minh";

    public DateTimeOffset? LastLoginAt { get; set; }

    public DateTimeOffset? LastActiveAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class BiometricProfileSeedDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Gender { get; set; } = string.Empty;

    public DateOnly DateOfBirth { get; set; }

    public decimal HeightCm { get; set; }

    public decimal CurrentWeightKg { get; set; }

    public decimal TargetWeightKg { get; set; }

    public decimal? CurrentBodyFatPercentage { get; set; }

    public decimal? GoalBodyFatPercentage { get; set; }

    public decimal? MuscleMassKg { get; set; }

    public string FitnessGoal { get; set; } = string.Empty;

    public string ActivityLevel { get; set; } = string.Empty;

    public string FitnessExperienceLevel { get; set; } = string.Empty;

    public string WorkoutLocationPreference { get; set; } = string.Empty;

    public int BaseTDEE { get; set; }

    public int BMR { get; set; }

    public int? DailyProteinTargetGram { get; set; }

    public int? DailyCarbTargetGram { get; set; }

    public int? DailyFatTargetGram { get; set; }

    public List<string>? Injuries { get; set; }

    public List<string>? Medications { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class UserPreferenceSeedDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public List<AllergyItemSeedDto>? Allergies { get; set; }

    public List<string>? FavoriteFoods { get; set; }

    public List<string>? DislikedFoods { get; set; }

    public string AgentPersona { get; set; } = string.Empty;

    public string MotivationStyle { get; set; } = string.Empty;

    public bool AutoOrderEnabled { get; set; }

    public decimal? MaxAutoOrderLimitDaily { get; set; }

    public decimal? MaxAutoOrderLimitPerOrder { get; set; }

    public bool DataSharingConsent { get; set; }

    public bool MarketingConsent { get; set; }

    public bool SmartPushEnabled { get; set; }

    public bool AllowAiGeneratedNotification { get; set; }

    public string? PreferredReminderTime { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class AllergyItemSeedDto
{
    public string AllergenName { get; set; } = string.Empty;

    public string? Severity { get; set; }

    public string? Notes { get; set; }
}

public sealed class GamificationProfileSeedDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public int CurrentLevel { get; set; }

    public long CurrentXP { get; set; }

    public int CurrentStreak { get; set; }

    public int LongestStreak { get; set; }

    public decimal SyncCoins { get; set; }

    public long AchievementPoints { get; set; }

    public int ConsecutivePerfectDays { get; set; }

    public DateTimeOffset? LastActivityDate { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class UserAchievementSeedDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid AchievementId { get; set; }

    public DateTimeOffset UnlockedAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class AchievementSeedDto
{
    public Guid Id { get; set; }

    public string Code { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int XpReward { get; set; }

    public int CoinReward { get; set; }

    [JsonIgnore]
    public string? IconUrl { get; set; }

    public string? RequirementJson { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}
