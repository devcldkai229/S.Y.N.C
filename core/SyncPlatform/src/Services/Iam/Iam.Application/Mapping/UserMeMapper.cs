using Iam.Application.DTOs;
using Iam.Domain.Enums;
using Iam.Domain.Models;

namespace Iam.Application.Mapping;

internal static class UserMeMapper
{
    public static BasicProfileDto ToBasicDto(User user) =>
        new(
            user.FullName,
            user.AvatarUrl,
            user.Email,
            user.PhoneNumber,
            user.PreferredLanguage,
            user.TimeZone,
            user.Role.ToString(),
            user.Status.ToString(),
            user.SubscriptionTier.ToString(),
            user.EmailVerified,
            user.PhoneVerified);

    public static FitnessProfileDto ToFitnessDto(BiometricProfile? profile) =>
        profile is null
            ? new FitnessProfileDto(
                IsConfigured: false,
                Gender: null,
                DateOfBirth: null,
                HeightCm: null,
                CurrentWeightKg: null,
                TargetWeightKg: null,
                CurrentBodyFatPercentage: null,
                GoalBodyFatPercentage: null,
                MuscleMassKg: null,
                FitnessGoal: null,
                ActivityLevel: null,
                FitnessExperienceLevel: null,
                WorkoutLocationPreference: null,
                BaseTDEE: null,
                BMR: null,
                DailyProteinTargetGram: null,
                DailyCarbTargetGram: null,
                DailyFatTargetGram: null,
                Injuries: [],
                Medications: [])
            : new FitnessProfileDto(
                IsConfigured: true,
                profile.Gender.ToString(),
                profile.DateOfBirth,
                profile.HeightCm,
                profile.CurrentWeightKg,
                profile.TargetWeightKg,
                profile.CurrentBodyFatPercentage,
                profile.GoalBodyFatPercentage,
                profile.MuscleMassKg,
                profile.FitnessGoal.ToString(),
                profile.ActivityLevel.ToString(),
                profile.FitnessExperienceLevel.ToString(),
                profile.WorkoutLocationPreference.ToString(),
                profile.BaseTDEE,
                profile.BMR,
                profile.DailyProteinTargetGram,
                profile.DailyCarbTargetGram,
                profile.DailyFatTargetGram,
                profile.Injuries ?? [],
                profile.Medications ?? []);

    public static AccountPreferencesDto ToPreferencesDto(UserPreference? preference) =>
        preference is null
            ? new AccountPreferencesDto(
                IsConfigured: false,
                Allergies: [],
                FavoriteFoods: [],
                DislikedFoods: [],
                AgentPersona: AgentPersona.FriendlyBuddy.ToString(),
                MotivationStyle: MotivationStyle.Supportive.ToString(),
                AutoOrderEnabled: false,
                MaxAutoOrderLimitDaily: null,
                MaxAutoOrderLimitPerOrder: null,
                DataSharingConsent: false,
                MarketingConsent: false)
            : new AccountPreferencesDto(
                IsConfigured: true,
                (preference.Allergies ?? [])
                    .Select(a => new AllergyItemDto(a.AllergenName, a.Severity, a.Notes))
                    .ToList(),
                preference.FavoriteFoods ?? [],
                preference.DislikedFoods ?? [],
                preference.AgentPersona.ToString(),
                preference.MotivationStyle.ToString(),
                preference.AutoOrderEnabled,
                preference.MaxAutoOrderLimitDaily,
                preference.MaxAutoOrderLimitPerOrder,
                preference.DataSharingConsent,
                preference.MarketingConsent);

    public static ProfileSettingsResponse ToProfileSettingsResponse(User user)
    {
        var (percent, hints) = Validation.ProfileCompletenessCalculator.Calculate(user);
        return new ProfileSettingsResponse(
            user.Id,
            ToBasicDto(user),
            ToFitnessDto(user.BiometricProfile),
            ToPreferencesDto(user.UserPreference),
            percent,
            hints);
    }

    public static GamificationSummaryDto? ToGamificationDto(GamificationProfile? profile) =>
        profile is null
            ? null
            : new GamificationSummaryDto(
                profile.CurrentLevel,
                profile.CurrentXP,
                profile.CurrentStreak,
                profile.LongestStreak,
                profile.SyncCoins,
                profile.AchievementPoints,
                profile.ConsecutivePerfectDays);

    public static VoucherInventoryItemDto ToVoucherDto(UserVoucher voucher)
    {
        var isExpired = voucher.ValidUntil is { } until && until < DateTimeOffset.UtcNow
                        && voucher.Status != VoucherStatus.Used;

        return new VoucherInventoryItemDto(
            voucher.Id,
            voucher.VoucherCode,
            voucher.Name,
            voucher.PromotionType,
            voucher.Value,
            voucher.Status.ToString(),
            voucher.AcquiredAt,
            voucher.UsedAt,
            voucher.ValidUntil,
            isExpired);
    }

    public static AchievementInventoryItemDto ToAchievementDto(UserAchievement userAchievement) =>
        new(
            userAchievement.AchievementId,
            userAchievement.Achievement.Code,
            userAchievement.Achievement.Name,
            userAchievement.Achievement.Description,
            userAchievement.Achievement.XPReward,
            userAchievement.Achievement.CoinReward,
            userAchievement.Achievement.IconUrl,
            userAchievement.UnlockedAt);
}
