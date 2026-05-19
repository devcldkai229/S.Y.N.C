using Libs.Shared.Enums;

namespace Roadmap.Domain.Models;

public class PersonalizedRoadmap : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public string RoadmapName { get; set; } = string.Empty;

    public string FitnessGoal { get; set; } = string.Empty;

    public string CurrentPhase { get; set; } = string.Empty;

    public DateTimeOffset StartDate { get; set; }

    public DateTimeOffset? ExpectedEndDate { get; set; }

    public decimal CurrentWeightKg { get; set; }

    public decimal TargetWeightKg { get; set; }

    public decimal InitialFatPercentage { get; set; }

    public decimal TargetFatPercentage { get; set; }

    public bool AdaptiveAiEnabled { get; set; }

    public bool AllowAiReschedule { get; set; }

    public bool AllowAiIntensityAdjustment { get; set; }

    public bool AllowAiRecoveryDeload { get; set; }

    public RoadmapStatus RoadmapStatus { get; set; }
}
