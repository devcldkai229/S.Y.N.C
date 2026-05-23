using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Mappers;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class BiometricProfileService : IBiometricProfileService
{
    private readonly IUserRepository _userRepository;
    private readonly IBiometricProfileRepository _biometricRepository;

    public BiometricProfileService(
        IUserRepository userRepository,
        IBiometricProfileRepository biometricRepository)
    {
        _userRepository = userRepository;
        _biometricRepository = biometricRepository;
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

        profile.CurrentWeightKg = dto.CurrentWeightKg;
        profile.TargetWeightKg = dto.TargetWeightKg;
        profile.FitnessGoal = dto.FitnessGoal;
        profile.ActivityLevel = dto.ActivityLevel;
        profile.FitnessExperienceLevel = dto.FitnessExperienceLevel;
        profile.WorkoutLocationPreference = dto.WorkoutLocationPreference;

        RecalculateBiometricTargets(profile);

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

    public async Task<BiometricProfileDto> LogWeightAsync(Guid userId, UpdateWeightDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdWithBiometricAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), userId);

        var profile = user.BiometricProfile 
            ?? throw new BadRequestException("Biometric profile must be initialized first.");

        profile.CurrentWeightKg = dto.CurrentWeightKg;

        RecalculateBiometricTargets(profile);

        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        return profile.ToDto();
    }

    private void RecalculateBiometricTargets(BiometricProfile profile)
    {
        // 1. Calculate Age
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        int age = today.Year - profile.DateOfBirth.Year;
        if (profile.DateOfBirth > today.AddYears(-age)) age--;
        if (age < 1) age = 1; // Safeguard for division or logic

        // 2. BMR (Mifflin - St.Jeor)
        double bmrDouble;
        if (profile.Gender == Gender.Male)
        {
            bmrDouble = (10 * (double)profile.CurrentWeightKg) + (6.25 * (double)profile.HeightCm) - (5 * age) + 5;
        }
        else
        {
            bmrDouble = (10 * (double)profile.CurrentWeightKg) + (6.25 * (double)profile.HeightCm) - (5 * age) - 161;
        }

        profile.BMR = (int)Math.Round(bmrDouble);

        // 3. TDEE (BMR * ActivityLevel AF multiplier)
        double multiplier = profile.ActivityLevel switch
        {
            ActivityLevel.Sedentary => 1.2,
            ActivityLevel.LightlyActive => 1.375,
            ActivityLevel.ModeratelyActive => 1.55,
            ActivityLevel.VeryActive => 1.725,
            ActivityLevel.Athlete => 1.9,
            _ => 1.2
        };

        profile.BaseTDEE = (int)Math.Round(profile.BMR * multiplier);

        // 4. Calorie Target (Tâm Anh Hospital principles)
        int calorieTarget = profile.FitnessGoal switch
        {
            FitnessGoal.LoseFat => Math.Max(profile.Gender == Gender.Male ? 1500 : 1200, profile.BaseTDEE - 500),
            FitnessGoal.BuildMuscle => profile.BaseTDEE + 300,
            _ => profile.BaseTDEE
        };

        // 5. Protein Target (1g = 4 kcal)
        double proteinPerKg = profile.FitnessGoal switch
        {
            FitnessGoal.LoseFat => 2.2,
            FitnessGoal.BuildMuscle => 2.0,
            _ => 1.6
        };

        int proteinGrams = (int)Math.Round(proteinPerKg * (double)profile.CurrentWeightKg);
        // Safety cap: protein calories must not exceed 40% of target calories
        if (proteinGrams * 4 > calorieTarget * 0.40)
        {
            proteinGrams = (int)Math.Round((calorieTarget * 0.35) / 4.0);
        }
        profile.DailyProteinTargetGram = proteinGrams;

        // 6. Fat Target (25% of calories, 1g = 9 kcal)
        int fatGrams = (int)Math.Round((calorieTarget * 0.25) / 9.0);
        profile.DailyFatTargetGram = fatGrams;

        // 7. Carb Target (Remaining calories, 1g = 4 kcal)
        int remainingCalories = calorieTarget - (proteinGrams * 4) - (fatGrams * 9);
        profile.DailyCarbTargetGram = Math.Max(0, (int)Math.Round(remainingCalories / 4.0));
    }
}
