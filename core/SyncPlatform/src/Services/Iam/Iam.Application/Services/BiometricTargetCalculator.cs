using Iam.Domain.Enums;
using Iam.Domain.Models;

namespace Iam.Application.Services;

/// <summary>
/// Shared BMR / TDEE / macro calculations used by onboarding and profile-settings flows.
/// </summary>
public static class BiometricTargetCalculator
{
    public static bool HasMinimumData(BiometricProfile profile) =>
        profile.DateOfBirth != default
        && profile.HeightCm > 0
        && profile.CurrentWeightKg > 0
        && profile.FitnessGoal != default
        && profile.ActivityLevel != default;

    public static void Recalculate(BiometricProfile profile)
    {
        if (!HasMinimumData(profile))
            return;

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var age = today.Year - profile.DateOfBirth.Year;
        if (profile.DateOfBirth > today.AddYears(-age))
            age--;
        if (age < 1)
            age = 1;

        var bmrDouble = profile.Gender == Gender.Male
            ? (10 * (double)profile.CurrentWeightKg) + (6.25 * (double)profile.HeightCm) - (5 * age) + 5
            : (10 * (double)profile.CurrentWeightKg) + (6.25 * (double)profile.HeightCm) - (5 * age) - 161;

        profile.BMR = (int)Math.Round(bmrDouble);

        var multiplier = profile.ActivityLevel switch
        {
            ActivityLevel.Sedentary => 1.2,
            ActivityLevel.LightlyActive => 1.375,
            ActivityLevel.ModeratelyActive => 1.55,
            ActivityLevel.VeryActive => 1.725,
            ActivityLevel.Athlete => 1.9,
            _ => 1.2
        };

        profile.BaseTDEE = (int)Math.Round(profile.BMR * multiplier);

        var genderFloor = profile.Gender == Gender.Male ? 1500 : 1200;
        var calorieTarget = profile.FitnessGoal switch
        {
            FitnessGoal.LoseFat => Math.Max(
                profile.BMR,
                Math.Max(genderFloor, profile.BaseTDEE - 500)),
            FitnessGoal.BuildMuscle => profile.BaseTDEE + 300,
            _ => profile.BaseTDEE
        };

        var proteinPerKg = profile.FitnessGoal switch
        {
            FitnessGoal.LoseFat => 2.2,
            FitnessGoal.BuildMuscle => 2.0,
            FitnessGoal.Maintain => 1.8,
            _ => 1.8
        };

        var proteinGrams = (int)Math.Round(proteinPerKg * (double)profile.CurrentWeightKg);
        if (proteinGrams * 4 > calorieTarget * 0.40)
            proteinGrams = (int)Math.Round((calorieTarget * 0.35) / 4.0);

        profile.DailyProteinTargetGram = proteinGrams;

        var fatGrams = (int)Math.Round((calorieTarget * 0.25) / 9.0);
        profile.DailyFatTargetGram = fatGrams;

        var remainingCalories = calorieTarget - (proteinGrams * 4) - (fatGrams * 9);
        profile.DailyCarbTargetGram = Math.Max(0, (int)Math.Round(remainingCalories / 4.0));
    }
}
