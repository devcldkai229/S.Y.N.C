using Libs.Shared.Common;
using Iam.Domain.Enums;

namespace Iam.Domain.Models;

public class BiometricProfile : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

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
