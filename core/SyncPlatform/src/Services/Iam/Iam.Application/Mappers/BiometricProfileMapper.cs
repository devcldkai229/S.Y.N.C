using Iam.Application.DTOs;
using Iam.Domain.Models;

namespace Iam.Application.Mappers;

public static class BiometricProfileMapper
{
    public static BiometricProfileDto ToDto(this BiometricProfile entity)
    {
        return new BiometricProfileDto
        {
            UserId = entity.UserId,
            Gender = entity.Gender,
            DateOfBirth = entity.DateOfBirth,
            HeightCm = entity.HeightCm,
            CurrentWeightKg = entity.CurrentWeightKg,
            TargetWeightKg = entity.TargetWeightKg,
            CurrentBodyFatPercentage = entity.CurrentBodyFatPercentage,
            GoalBodyFatPercentage = entity.GoalBodyFatPercentage,
            MuscleMassKg = entity.MuscleMassKg,
            FitnessGoal = entity.FitnessGoal,
            ActivityLevel = entity.ActivityLevel,
            FitnessExperienceLevel = entity.FitnessExperienceLevel,
            WorkoutLocationPreference = entity.WorkoutLocationPreference,
            BaseTDEE = entity.BaseTDEE,
            BMR = entity.BMR,
            DailyProteinTargetGram = entity.DailyProteinTargetGram,
            DailyCarbTargetGram = entity.DailyCarbTargetGram,
            DailyFatTargetGram = entity.DailyFatTargetGram,
            Injuries = entity.Injuries,
            Medications = entity.Medications
        };
    }
}
