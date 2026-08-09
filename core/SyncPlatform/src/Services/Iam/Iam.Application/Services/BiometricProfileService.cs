using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Mappers;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.Extensions.Logging;

namespace Iam.Application.Services;

public class BiometricProfileService : IBiometricProfileService
{
    private readonly IUserRepository _userRepository;
    private readonly IBiometricProfileRepository _biometricRepository;
    private readonly IBiometricHistoryRepository _historyRepository;
    private readonly IRoadmapBodyMetricsClient _roadmapBodyMetrics;
    private readonly ILogger<BiometricProfileService> _logger;

    public BiometricProfileService(
        IUserRepository userRepository,
        IBiometricProfileRepository biometricRepository,
        IBiometricHistoryRepository historyRepository,
        IRoadmapBodyMetricsClient roadmapBodyMetrics,
        ILogger<BiometricProfileService> logger)
    {
        _userRepository = userRepository;
        _biometricRepository = biometricRepository;
        _historyRepository = historyRepository;
        _roadmapBodyMetrics = roadmapBodyMetrics;
        _logger = logger;
    }

    public async Task<BiometricProfileDto> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        if (user.BiometricProfile == null)
            throw new NotFoundException("BiometricProfile has not been initialized for this user.");

        return user.BiometricProfile.ToDto();
    }

    public async Task<BiometricProfileDto> SaveBasicInfoAsync(Guid userId, OnboardingStep1Dto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile;
        bool isNew = false;

        if (profile == null)
        {
            profile = new BiometricProfile { UserId = userId };
            isNew = true;
        }

        profile.Gender = dto.Gender;
        profile.DateOfBirth = dto.DateOfBirth;
        profile.HeightCm = dto.HeightCm;

        if (isNew)
        {
            await _biometricRepository.CreateAsync(profile, cancellationToken);
        }
        else
        {
            await _biometricRepository.UpdateAsync(profile, cancellationToken);
        }

        return profile.ToDto();
    }

    public async Task<BiometricProfileDto> SaveGoalsAsync(Guid userId, OnboardingStep2Dto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile 
            ?? throw new BadRequestException("Please complete basic information (Step 1) first.");

        // Đổi goal/activity = trigger ProfileChange → engine phải tính lại nền
        // từ formula; nhả quyền quản targets về công thức tới lần engine chạy sau.
        if (profile.FitnessGoal != dto.FitnessGoal || profile.ActivityLevel != dto.ActivityLevel)
            profile.TargetsManagedByEngine = false;

        profile.CurrentWeightKg = dto.CurrentWeightKg;
        profile.TargetWeightKg = dto.TargetWeightKg;
        profile.FitnessGoal = dto.FitnessGoal;
        profile.ActivityLevel = dto.ActivityLevel;
        profile.FitnessExperienceLevel = dto.FitnessExperienceLevel;
        profile.WorkoutLocationPreference = dto.WorkoutLocationPreference;

        BiometricTargetCalculator.Recalculate(profile);

        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        return profile.ToDto();
    }

    public async Task<BiometricProfileDto> SaveCompositionAsync(Guid userId, OnboardingStep3Dto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile 
            ?? throw new BadRequestException("Biometric profile must be initialized first.");

        profile.CurrentBodyFatPercentage = dto.CurrentBodyFatPercentage;
        profile.GoalBodyFatPercentage = dto.GoalBodyFatPercentage;
        profile.MuscleMassKg = dto.MuscleMassKg;

        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        return profile.ToDto();
    }

    public async Task<BiometricProfileDto> SaveSafeguardsAsync(Guid userId, OnboardingStep4Dto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile 
            ?? throw new BadRequestException("Biometric profile must be initialized first.");

        profile.Injuries = dto.Injuries;
        profile.Medications = dto.Medications;

        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        return profile.ToDto();
    }

    public async Task<OnboardingCompleteResultDto> CompleteOnboardingAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithOnboardingProfilesAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile
            ?? throw new BadRequestException("Complete your fitness profile before finishing onboarding.");

        if (!BiometricTargetCalculator.HasMinimumData(profile))
            throw new BadRequestException("Missing required biometric fields (gender, date of birth, height, weight, goal, activity).");

        if (user.UserPreference is null
            || user.UserPreference.Allergies is not { Count: > 0 })
        {
            throw new BadRequestException("Set at least one allergy (or \"no known allergies\") in account preferences before finishing.");
        }

        BiometricTargetCalculator.Recalculate(profile);
        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        var aiCreated = false;
        if (user.AIContextProfile is null)
        {
            user.AIContextProfile = new AIContextProfile
            {
                UserId = userId,
                AIConfidenceScore = 1.0m,
                AdherenceScore = 1.0m,
                NutritionComplianceScore = 1.0m,
                WorkoutComplianceScore = 1.0m,
                BurnoutRiskScore = 0m,
                ChurnRiskScore = 0m,
                MotivationScore = 1.0m,
                RecoveryScore = 1.0m,
            };
            aiCreated = true;
        }

        var gamificationCreated = false;
        if (user.GamificationProfile is null)
        {
            user.GamificationProfile = new GamificationProfile
            {
                UserId = userId,
                CurrentLevel = 1,
                CurrentXP = 0,
                CurrentStreak = 0,
                LongestStreak = 0,
                SyncCoins = 0m,
                AchievementPoints = 0,
                ConsecutivePerfectDays = 0,
            };
            gamificationCreated = true;
        }

        if (aiCreated || gamificationCreated)
            await _userRepository.UpdateAsync(user, cancellationToken);

        return new OnboardingCompleteResultDto(profile.ToDto(), aiCreated, gamificationCreated);
    }

    public async Task<BiometricProfileDto> LogWeightAsync(Guid userId, UpdateWeightDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile 
            ?? throw new BadRequestException("Biometric profile must be initialized first.");

        profile.CurrentWeightKg = dto.CurrentWeightKg;

        BiometricTargetCalculator.Recalculate(profile);

        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        // Ghi BiometricHistory — nguồn dữ liệu của Adaptive Coaching Engine
        // (weigh-in từ app UI cũng phải vào chuỗi, không chỉ từ AI chat).
        await _historyRepository.CreateAsync(new BiometricHistory
        {
            UserId = userId,
            RecordedAtUtc = DateTime.UtcNow,
            WeightKg = dto.CurrentWeightKg,
            Source = "Manual",
        }, cancellationToken);

        // Mirror cân sang PersonalizedRoadmap (best-effort) — overview AI Roadmap không bị stale.
        await _roadmapBodyMetrics.SyncAsync(
            userId,
            dto.CurrentWeightKg,
            profile.CurrentBodyFatPercentage,
            cancellationToken);

        // Fire-and-forget signal — không chạy engine trên request path; CYN/SmartPush/weekly recalc pick up.
        _logger.LogInformation(
            "Adaptive WeighInLogged user={UserId} weightKg={WeightKg}",
            userId, dto.CurrentWeightKg);

        return profile.ToDto();
    }
}
