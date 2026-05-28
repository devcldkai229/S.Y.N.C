using Iam.Domain.Enums;

namespace Iam.Application.DTOs;

public class BiometricProfileDto
{
    public Guid UserId { get; set; }
    public Gender Gender { get; set; }
    public DateOnly DateOfBirth { get; set; }
    public decimal HeightCm { get; set; }
    public decimal CurrentWeightKg { get; set; }
    public decimal TargetWeightKg { get; set; }
    public decimal? CurrentBodyFatPercentage { get; set; }
    public decimal? GoalBodyFatPercentage { get; set; }
    public decimal? MuscleMassKg { get; set; }
    public FitnessGoal FitnessGoal { get; set; }
    public ActivityLevel ActivityLevel { get; set; }
    public FitnessExperienceLevel FitnessExperienceLevel { get; set; }
    public WorkoutLocationPreference WorkoutLocationPreference { get; set; }
    public int BaseTDEE { get; set; }
    public int BMR { get; set; }
    public int? DailyProteinTargetGram { get; set; }
    public int? DailyCarbTargetGram { get; set; }
    public int? DailyFatTargetGram { get; set; }
    public List<string>? Injuries { get; set; }
    public List<string>? Medications { get; set; }
}

public class OnboardingStep1Dto
{
    public Gender Gender { get; set; }
    public DateOnly DateOfBirth { get; set; }
    public decimal HeightCm { get; set; }
}

public class OnboardingStep2Dto
{
    public decimal CurrentWeightKg { get; set; }
    public decimal TargetWeightKg { get; set; }
    public FitnessGoal FitnessGoal { get; set; }
    public ActivityLevel ActivityLevel { get; set; }
    public FitnessExperienceLevel FitnessExperienceLevel { get; set; }
    public WorkoutLocationPreference WorkoutLocationPreference { get; set; }
}

public class OnboardingStep3Dto
{
    public decimal? CurrentBodyFatPercentage { get; set; }
    public decimal? GoalBodyFatPercentage { get; set; }
    public decimal? MuscleMassKg { get; set; }
}

public class OnboardingStep4Dto
{
    public List<string>? Injuries { get; set; }
    public List<string>? Medications { get; set; }
}

public class UpdateWeightDto
{
    public decimal CurrentWeightKg { get; set; }
}

public sealed record OnboardingCompleteResultDto(
    BiometricProfileDto Biometric,
    bool AIContextProfileCreated,
    bool GamificationProfileCreated);
