using Iam.Application.Abstractions;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Mapping;
using Iam.Application.Validation;
using Libs.Auth.Context;
using Libs.Storage.Services;
using Iam.Domain.Enums;
using Iam.Domain.Models;

namespace Iam.Application.Services;

public sealed class UserMeService
{
    private readonly IUserMeRepository _repository;
    private readonly ICurrentUserContext _currentUser;
    private readonly IAchievementService _achievementService;
    private readonly IMediaUrlResolver _media;

    public UserMeService(
        IUserMeRepository repository,
        ICurrentUserContext currentUser,
        IAchievementService achievementService,
        IMediaUrlResolver media)
    {
        _repository = repository;
        _currentUser = currentUser;
        _achievementService = achievementService;
        _media = media;
    }

    public async Task<ProfileSettingsResponse> GetProfileSettingsAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.RequireUserId();
        var user = await _repository.GetUserWithProfilesAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        return UserMeMapper.ToProfileSettingsResponse(user, _media);
    }

    public async Task<InventoryResponse> GetInventoryAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.RequireUserId();

        _ = await _repository.GetUserWithProfilesAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        // Auto-check and unlock any newly met profile-based achievements
        await _achievementService.CheckAndUnlockAsync(userId, cancellationToken);

        var gamification = await _repository.GetGamificationAsync(userId, cancellationToken);
        var vouchers = await _repository.GetVouchersAsync(userId, cancellationToken);
        var achievements = await _repository.GetAchievementsAsync(userId, cancellationToken);
        var allAchievements = await _repository.GetAllAchievementsAsync(cancellationToken);
        var unlockedIds = await _repository.GetUnlockedAchievementIdsAsync(userId, cancellationToken);

        var voucherDtos = vouchers
            .OrderByDescending(v => v.AcquiredAt)
            .Select(UserMeMapper.ToVoucherDto)
            .ToList();

        var achievementDtos = achievements
            .OrderByDescending(a => a.UnlockedAt)
            .Select(a => UserMeMapper.ToAchievementDto(a, _media))
            .ToList();

        var inProgressDtos = allAchievements
            .Where(a => !unlockedIds.Contains(a.Id))
            .Select(a => UserMeMapper.ToProgressDto(a, gamification, _media))
            .OfType<AchievementProgressDto>()
            .Where(p => p.CurrentValue > 0)
            .OrderByDescending(p => (double)p.CurrentValue / p.RequiredValue)
            .ToList();

        return new InventoryResponse(
            UserMeMapper.ToGamificationDto(gamification),
            voucherDtos,
            achievementDtos,
            inProgressDtos,
            voucherDtos.Count,
            achievementDtos.Count);
    }

    public async Task<ProfileSettingsResponse> UpdateBasicProfileAsync(
        UpdateBasicProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        ProfileValidators.ValidateBasicUpdate(request);

        var user = await GetUserForUpdateAsync(cancellationToken);

        if (request.FullName is not null)
            user.FullName = request.FullName.Trim();

        if (request.AvatarUrl is not null)
            user.AvatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl)
                ? null
                : _media.NormalizeForStorage(request.AvatarUrl.Trim());

        if (request.BackgroundImageUrl is not null)
            user.BackgroundImageUrl = string.IsNullOrWhiteSpace(request.BackgroundImageUrl)
                ? null
                : _media.NormalizeForStorage(request.BackgroundImageUrl.Trim());

        if (request.PreferredLanguage is not null)
            user.PreferredLanguage = request.PreferredLanguage.Trim();

        if (request.TimeZone is not null)
            user.TimeZone = request.TimeZone.Trim();

        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _repository.SaveChangesAsync(cancellationToken);

        return UserMeMapper.ToProfileSettingsResponse(user, _media);
    }

    public async Task<ProfileSettingsResponse> UpdateFitnessProfileAsync(
        UpdateFitnessProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var user = await GetUserForUpdateAsync(cancellationToken);
        var isCreate = user.BiometricProfile is null;

        ProfileValidators.ValidateFitnessUpdate(request, isCreate);

        var profile = user.BiometricProfile ?? CreateDefaultBiometricProfile(user.Id);
        if (isCreate)
            user.BiometricProfile = profile;

        ApplyFitnessPatch(profile, request, isCreate);

        if (ShouldRecalculateTargets(request) && BiometricTargetCalculator.HasMinimumData(profile))
            BiometricTargetCalculator.Recalculate(profile);

        profile.UpdatedAt = DateTimeOffset.UtcNow;
        user.UpdatedAt = DateTimeOffset.UtcNow;

        await _repository.SaveChangesAsync(cancellationToken);
        return UserMeMapper.ToProfileSettingsResponse(user, _media);
    }

    public async Task<ProfileSettingsResponse> UpdateAccountPreferencesAsync(
        UpdateAccountPreferencesRequest request,
        CancellationToken cancellationToken = default)
    {
        ProfileValidators.ValidateAccountPreferencesUpdate(request);

        var user = await GetUserForUpdateAsync(cancellationToken);
        var preference = user.UserPreference ?? CreateDefaultUserPreference(user.Id);
        if (user.UserPreference is null)
            user.UserPreference = preference;

        ApplyPreferencesPatch(preference, request);
        ValidateAutoOrderState(preference);

        preference.UpdatedAt = DateTimeOffset.UtcNow;
        user.UpdatedAt = DateTimeOffset.UtcNow;

        await _repository.SaveChangesAsync(cancellationToken);
        return UserMeMapper.ToProfileSettingsResponse(user, _media);
    }

    private async Task<User> GetUserForUpdateAsync(CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        return await _repository.GetUserForUpdateAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);
    }

    private static bool ShouldRecalculateTargets(UpdateFitnessProfileRequest request) =>
        request.Gender is not null
        || request.DateOfBirth is not null
        || request.HeightCm is not null
        || request.CurrentWeightKg is not null
        || request.FitnessGoal is not null
        || request.ActivityLevel is not null;

    private static BiometricProfile CreateDefaultBiometricProfile(Guid userId) =>
        new()
        {
            UserId = userId,
            CreatedAt = DateTimeOffset.UtcNow
        };

    private static UserPreference CreateDefaultUserPreference(Guid userId) =>
        new()
        {
            UserId = userId,
            AgentPersona = AgentPersona.FriendlyBuddy,
            MotivationStyle = MotivationStyle.Supportive,
            AutoOrderEnabled = false,
            DataSharingConsent = false,
            MarketingConsent = false,
            CreatedAt = DateTimeOffset.UtcNow
        };

    private static void ApplyFitnessPatch(BiometricProfile profile, UpdateFitnessProfileRequest request, bool isCreate)
    {
        if (isCreate || request.Gender is not null)
            profile.Gender = Enum.Parse<Gender>(request.Gender!, ignoreCase: true);

        if (isCreate || request.DateOfBirth is not null)
            profile.DateOfBirth = request.DateOfBirth!.Value;

        if (isCreate || request.HeightCm is not null)
            profile.HeightCm = request.HeightCm!.Value;

        if (isCreate || request.CurrentWeightKg is not null)
            profile.CurrentWeightKg = request.CurrentWeightKg!.Value;

        if (isCreate || request.TargetWeightKg is not null)
            profile.TargetWeightKg = request.TargetWeightKg!.Value;

        if (request.CurrentBodyFatPercentage is not null)
            profile.CurrentBodyFatPercentage = request.CurrentBodyFatPercentage;

        if (request.GoalBodyFatPercentage is not null)
            profile.GoalBodyFatPercentage = request.GoalBodyFatPercentage;

        if (request.MuscleMassKg is not null)
            profile.MuscleMassKg = request.MuscleMassKg;

        if (isCreate || request.FitnessGoal is not null)
            profile.FitnessGoal = Enum.Parse<FitnessGoal>(request.FitnessGoal!, ignoreCase: true);

        if (isCreate || request.ActivityLevel is not null)
            profile.ActivityLevel = Enum.Parse<ActivityLevel>(request.ActivityLevel!, ignoreCase: true);

        if (isCreate || request.FitnessExperienceLevel is not null)
            profile.FitnessExperienceLevel = Enum.Parse<FitnessExperienceLevel>(request.FitnessExperienceLevel!, ignoreCase: true);

        if (isCreate || request.WorkoutLocationPreference is not null)
            profile.WorkoutLocationPreference = Enum.Parse<WorkoutLocationPreference>(request.WorkoutLocationPreference!, ignoreCase: true);

        if (request.BaseTDEE is not null)
            profile.BaseTDEE = request.BaseTDEE.Value;

        if (request.BMR is not null)
            profile.BMR = request.BMR.Value;

        if (request.DailyProteinTargetGram is not null)
            profile.DailyProteinTargetGram = request.DailyProteinTargetGram;

        if (request.DailyCarbTargetGram is not null)
            profile.DailyCarbTargetGram = request.DailyCarbTargetGram;

        if (request.DailyFatTargetGram is not null)
            profile.DailyFatTargetGram = request.DailyFatTargetGram;

        if (request.Injuries is not null)
            profile.Injuries = ListNormalizer.NormalizeStrings(request.Injuries);

        if (request.Medications is not null)
            profile.Medications = ListNormalizer.NormalizeStrings(request.Medications);
    }

    private static void ApplyPreferencesPatch(UserPreference preference, UpdateAccountPreferencesRequest request)
    {
        if (request.Allergies is not null)
        {
            preference.Allergies = request.Allergies
                .Select(a => new AllergyItem(
                    a.AllergenName.Trim(),
                    string.IsNullOrWhiteSpace(a.Severity) ? null : a.Severity.Trim(),
                    string.IsNullOrWhiteSpace(a.Notes) ? null : a.Notes.Trim()))
                .ToList();
        }

        if (request.FavoriteFoods is not null)
            preference.FavoriteFoods = ListNormalizer.NormalizeStrings(request.FavoriteFoods);

        if (request.DislikedFoods is not null)
            preference.DislikedFoods = ListNormalizer.NormalizeStrings(request.DislikedFoods);

        if (request.AgentPersona is not null)
            preference.AgentPersona = Enum.Parse<AgentPersona>(request.AgentPersona, ignoreCase: true);

        if (request.MotivationStyle is not null)
            preference.MotivationStyle = Enum.Parse<MotivationStyle>(request.MotivationStyle, ignoreCase: true);

        if (request.AutoOrderEnabled is not null)
            preference.AutoOrderEnabled = request.AutoOrderEnabled.Value;

        if (request.MaxAutoOrderLimitDaily is not null)
            preference.MaxAutoOrderLimitDaily = request.MaxAutoOrderLimitDaily;

        if (request.MaxAutoOrderLimitPerOrder is not null)
            preference.MaxAutoOrderLimitPerOrder = request.MaxAutoOrderLimitPerOrder;

        if (request.DataSharingConsent is not null)
            preference.DataSharingConsent = request.DataSharingConsent.Value;

        if (request.MarketingConsent is not null)
            preference.MarketingConsent = request.MarketingConsent.Value;
    }

    private static void ValidateAutoOrderState(UserPreference preference)
    {
        if (!preference.AutoOrderEnabled)
            return;

        var errors = new Dictionary<string, string[]>();

        if (preference.MaxAutoOrderLimitDaily is null or <= 0)
            errors[nameof(preference.MaxAutoOrderLimitDaily)] = ["Daily auto-order limit is required when auto-order is enabled."];

        if (preference.MaxAutoOrderLimitPerOrder is null or <= 0)
            errors[nameof(preference.MaxAutoOrderLimitPerOrder)] = ["Per-order auto-order limit is required when auto-order is enabled."];

        if (preference.MaxAutoOrderLimitDaily is > 0
            && preference.MaxAutoOrderLimitPerOrder is > 0
            && preference.MaxAutoOrderLimitPerOrder > preference.MaxAutoOrderLimitDaily)
        {
            errors[nameof(preference.MaxAutoOrderLimitPerOrder)] = ["Per-order limit cannot exceed the daily limit."];
        }

        if (errors.Count > 0)
            throw new AppValidationException(errors);
    }
}
