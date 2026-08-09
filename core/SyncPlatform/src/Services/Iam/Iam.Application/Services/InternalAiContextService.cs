using Iam.Application.DTOs;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class InternalAiContextService : IInternalAiContextService
{
    private const int FreeAiQuotaPerMonth = 30;

    private readonly IUserRepository _userRepository;

    public InternalAiContextService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<InternalAiContextDto?> GetFullContextAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        // Tải User kèm các onboarding profiles (Biometric/Preference/AIContext/Gamification).
        var user = await _userRepository.GetByIdWithOnboardingProfilesAsync(userId, cancellationToken);
        if (user == null)
            return null;

        var dto = new InternalAiContextDto
        {
            UserId = user.Id,
            PreferredLanguage = string.IsNullOrWhiteSpace(user.PreferredLanguage) ? "vi" : user.PreferredLanguage,
            SubscriptionTier = user.SubscriptionTier.ToString(),
            FullName = string.IsNullOrWhiteSpace(user.FullName) ? null : user.FullName.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(user.PhoneNumber) ? null : user.PhoneNumber.Trim(),
        };

        var pref = user.UserPreference;
        if (pref != null)
        {
            dto.AgentPersona = pref.AgentPersona.ToString();
            dto.MotivationStyle = pref.MotivationStyle.ToString();
            dto.AutoOrderEnabled = pref.AutoOrderEnabled;
            dto.MaxAutoOrderLimitPerOrder = pref.MaxAutoOrderLimitPerOrder;
            dto.MaxAutoOrderLimitDaily = pref.MaxAutoOrderLimitDaily;
            if (pref.Allergies != null)
                dto.Allergies = pref.Allergies.Select(a => a.AllergenName).ToList();
            if (pref.DislikedFoods != null)
                dto.DislikedFoods = pref.DislikedFoods.ToList();
        }

        var bio = user.BiometricProfile;
        if (bio != null)
        {
            dto.FitnessGoal = bio.FitnessGoal.ToString();
            dto.ActivityLevel = bio.ActivityLevel.ToString();
            dto.ExperienceLevel = bio.FitnessExperienceLevel.ToString();
            dto.Gender = bio.Gender.ToString();
            dto.CurrentWeightKg = bio.CurrentWeightKg;
            dto.TargetWeightKg = bio.TargetWeightKg;
            dto.HeightCm = bio.HeightCm;
            dto.CurrentBodyFatPercentage = bio.CurrentBodyFatPercentage;
            dto.GoalBodyFatPercentage = bio.GoalBodyFatPercentage;
            dto.MuscleMassKg = bio.MuscleMassKg;
            dto.WorkoutLocationPreference = bio.WorkoutLocationPreference.ToString();
            dto.BaseTDEE = bio.BaseTDEE;
            dto.Bmr = bio.BMR;
            dto.DailyProteinTargetGram = bio.DailyProteinTargetGram;
            dto.DailyCarbTargetGram = bio.DailyCarbTargetGram;
            dto.DailyFatTargetGram = bio.DailyFatTargetGram;
            dto.DailyCalorieTarget = bio.DailyCalorieTarget;
            dto.TargetsManagedByEngine = bio.TargetsManagedByEngine;
            dto.TargetsAdjustedAtUtc = bio.TargetsAdjustedAtUtc;
            if (bio.Injuries != null)
                dto.Injuries = bio.Injuries.ToList();
            if (bio.Medications != null)
                dto.Medications = bio.Medications.ToList();
        }

        var ai = user.AIContextProfile;
        if (ai != null)
        {
            dto.AdherenceScore = ai.AdherenceScore;
            dto.BurnoutRiskScore = ai.BurnoutRiskScore;
            dto.RecoveryScore = ai.RecoveryScore;
            dto.MotivationScore = ai.MotivationScore;
            dto.CurrentMood = ai.CurrentMood;
            dto.PeakEnergyTimeWindow = ai.PeakEnergyTimeWindow;
        }

        return dto;
    }

    public async Task<InternalAiContextDto?> PatchAsync(
        Guid userId,
        InternalPatchAiContextDto patch,
        CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithOnboardingProfilesAsync(userId, cancellationToken);
        if (user == null)
            return null;

        if (user.AIContextProfile is null)
        {
            user.AIContextProfile = new AIContextProfile
            {
                UserId = userId,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow,
            };
        }

        var ai = user.AIContextProfile;
        if (patch.AdherenceScore.HasValue) ai.AdherenceScore = patch.AdherenceScore.Value;
        if (patch.BurnoutRiskScore.HasValue) ai.BurnoutRiskScore = patch.BurnoutRiskScore.Value;
        if (patch.RecoveryScore.HasValue) ai.RecoveryScore = patch.RecoveryScore.Value;
        if (patch.ChurnRiskScore.HasValue) ai.ChurnRiskScore = patch.ChurnRiskScore.Value;
        if (patch.MotivationScore.HasValue) ai.MotivationScore = patch.MotivationScore.Value;
        if (!string.IsNullOrWhiteSpace(patch.CurrentMood)) ai.CurrentMood = patch.CurrentMood.Trim();
        ai.UpdatedAt = DateTimeOffset.UtcNow;

        await _userRepository.SaveChangesAsync(cancellationToken);
        return await GetFullContextAsync(userId, cancellationToken);
    }

    public async Task<InternalAiQuotaResultDto?> TryConsumeAiQuotaAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user == null)
            return null;

        var periodKey = DateTime.UtcNow.ToString("yyyy-MM");
        if (!string.Equals(user.AiUsagePeriodKey, periodKey, StringComparison.Ordinal))
        {
            user.AiUsagePeriodKey = periodKey;
            user.AiUsageCount = 0;
        }

        var limit = MonthlyLimitForTier(user.SubscriptionTier);
        if (limit > 0 && user.AiUsageCount >= limit)
        {
            return new InternalAiQuotaResultDto
            {
                Allowed = false,
                Used = user.AiUsageCount,
                Limit = limit,
                PeriodKey = periodKey,
                SubscriptionTier = user.SubscriptionTier.ToString(),
            };
        }

        user.AiUsageCount++;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        return new InternalAiQuotaResultDto
        {
            Allowed = true,
            Used = user.AiUsageCount,
            Limit = limit,
            PeriodKey = periodKey,
            SubscriptionTier = user.SubscriptionTier.ToString(),
        };
    }

    private static int MonthlyLimitForTier(SubscriptionTier tier) =>
        tier switch
        {
            SubscriptionTier.Premium => 0,
            SubscriptionTier.Ultra => 0,
            _ => FreeAiQuotaPerMonth,
        };
}
