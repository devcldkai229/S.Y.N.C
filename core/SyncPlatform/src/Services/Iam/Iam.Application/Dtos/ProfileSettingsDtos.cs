namespace Iam.Application.DTOs;

public sealed record BasicProfileDto(
    string FullName,
    string? AvatarUrl,
    string? BackgroundImageUrl,
    string Email,
    string? PhoneNumber,
    string PreferredLanguage,
    string TimeZone,
    string Role,
    string Status,
    string SubscriptionTier,
    bool EmailVerified,
    bool PhoneVerified);

public sealed record FitnessProfileDto(
    bool IsConfigured,
    string? Gender,
    DateOnly? DateOfBirth,
    decimal? HeightCm,
    decimal? CurrentWeightKg,
    decimal? TargetWeightKg,
    decimal? CurrentBodyFatPercentage,
    decimal? GoalBodyFatPercentage,
    decimal? MuscleMassKg,
    string? FitnessGoal,
    string? ActivityLevel,
    string? FitnessExperienceLevel,
    string? WorkoutLocationPreference,
    int? BaseTDEE,
    int? BMR,
    int? DailyProteinTargetGram,
    int? DailyCarbTargetGram,
    int? DailyFatTargetGram,
    IReadOnlyList<string> Injuries,
    IReadOnlyList<string> Medications);

public sealed record AccountPreferencesDto(
    bool IsConfigured,
    IReadOnlyList<AllergyItemDto> Allergies,
    IReadOnlyList<string> FavoriteFoods,
    IReadOnlyList<string> DislikedFoods,
    string AgentPersona,
    string MotivationStyle,
    bool AutoOrderEnabled,
    decimal? MaxAutoOrderLimitDaily,
    decimal? MaxAutoOrderLimitPerOrder,
    bool DataSharingConsent,
    bool MarketingConsent);

public sealed record ProfileSettingsResponse(
    Guid UserId,
    BasicProfileDto Basic,
    FitnessProfileDto Fitness,
    AccountPreferencesDto Preferences,
    int ProfileCompletenessPercent,
    IReadOnlyList<string> MissingProfileHints);

public sealed record UpdateBasicProfileRequest(
    string? FullName,
    string? AvatarUrl,
    string? BackgroundImageUrl,
    string? PreferredLanguage,
    string? TimeZone);

public sealed record UpdateFitnessProfileRequest(
    string? Gender,
    DateOnly? DateOfBirth,
    decimal? HeightCm,
    decimal? CurrentWeightKg,
    decimal? TargetWeightKg,
    decimal? CurrentBodyFatPercentage,
    decimal? GoalBodyFatPercentage,
    decimal? MuscleMassKg,
    string? FitnessGoal,
    string? ActivityLevel,
    string? FitnessExperienceLevel,
    string? WorkoutLocationPreference,
    int? BaseTDEE,
    int? BMR,
    int? DailyProteinTargetGram,
    int? DailyCarbTargetGram,
    int? DailyFatTargetGram,
    IReadOnlyList<string>? Injuries,
    IReadOnlyList<string>? Medications);

public sealed record UpdateAccountPreferencesRequest(
    IReadOnlyList<AllergyItemDto>? Allergies,
    IReadOnlyList<string>? FavoriteFoods,
    IReadOnlyList<string>? DislikedFoods,
    string? AgentPersona,
    string? MotivationStyle,
    bool? AutoOrderEnabled,
    decimal? MaxAutoOrderLimitDaily,
    decimal? MaxAutoOrderLimitPerOrder,
    bool? DataSharingConsent,
    bool? MarketingConsent);
