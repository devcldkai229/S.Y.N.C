using Libs.Shared.Enums;

namespace Roadmap.Application.DTOs;

public class PersonalizedRoadmapDto
{
    public Guid Id { get; set; }
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
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreatePersonalizedRoadmapDto
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
    public RoadmapStatus RoadmapStatus { get; set; } = RoadmapStatus.Active;
}

public class UpdatePersonalizedRoadmapDto
{
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
