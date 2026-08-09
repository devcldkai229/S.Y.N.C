using Libs.Shared.Enums;

namespace Roadmap.Application.DTOs;

/// <summary>Partial update for AI-managed PersonalizedRoadmap.</summary>
public class InternalPatchPersonalizedRoadmapDto
{
    public string? RoadmapName { get; set; }
    public string? FitnessGoal { get; set; }
    public string? CurrentPhase { get; set; }
    public decimal? CurrentWeightKg { get; set; }
    public decimal? TargetWeightKg { get; set; }
    public decimal? InitialFatPercentage { get; set; }
    public decimal? TargetFatPercentage { get; set; }
    public bool? AdaptiveAiEnabled { get; set; }
    public bool? AllowAiReschedule { get; set; }
    public bool? AllowAiIntensityAdjustment { get; set; }
    public bool? AllowAiRecoveryDeload { get; set; }
    public RoadmapStatus? RoadmapStatus { get; set; }
}

/// <summary>Sync body metrics onto the user's active PersonalizedRoadmap (weigh-in / adaptive).</summary>
public class InternalSyncBodyMetricsDto
{
    public decimal? CurrentWeightKg { get; set; }
    public decimal? TargetWeightKg { get; set; }
    public decimal? InitialFatPercentage { get; set; }
    public decimal? TargetFatPercentage { get; set; }
    public string? CurrentPhase { get; set; }
}

public class InternalCreatePersonalizedRoadmapRequestDto : CreatePersonalizedRoadmapDto;

public class InternalScheduleSessionRequestDto : ScheduleSessionDto
{
}

public class InternalSubstituteExerciseRequestDto
{
    public Guid UserId { get; set; }
    public Guid ExerciseId { get; set; }
    public Guid? ReplaceExerciseId { get; set; }
    public string? ExerciseName { get; set; }
    public string Reason { get; set; } = string.Empty;
}
