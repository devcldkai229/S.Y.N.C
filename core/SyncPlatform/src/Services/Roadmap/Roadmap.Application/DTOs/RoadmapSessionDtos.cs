using Libs.Shared.Enums;

namespace Roadmap.Application.DTOs;

public class RoadmapSessionDto
{
    public Guid Id { get; set; }
    public Guid RoadmapId { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    public string ScheduledTime { get; set; } = string.Empty;
    public string Timezone { get; set; } = string.Empty;
    public string SessionType { get; set; } = string.Empty;
    public string SessionTitle { get; set; } = string.Empty;
    public int EstimatedDurationMinutes { get; set; }
    public bool NotificationEnabled { get; set; }
    public int NotificationMinutesBefore { get; set; }
    public bool AiGenerated { get; set; }
    public SessionStatus SessionStatus { get; set; }
    public List<ExecutionBlockDto> ExecutionBlocks { get; set; } = [];
    public DateTimeOffset CreatedAt { get; set; }
}

public class ExecutionBlockDto
{
    public int Order { get; set; }
    public Guid ExerciseId { get; set; }
    public string ExerciseName { get; set; } = string.Empty;
    public Guid? ExerciseAssetId { get; set; }
    public int TargetSets { get; set; }
    public int TargetReps { get; set; }
    public decimal TargetWeightKg { get; set; }
    public int RestSeconds { get; set; }
    public string Tempo { get; set; } = string.Empty;
    public string? ExerciseNotes { get; set; }
}

/// <summary>
/// AI Flow — Backend AI schedules a session as part of a PersonalizedRoadmap.
/// RoadmapId is required. ExecutionBlocks are provided explicitly.
/// </summary>
public class ScheduleSessionDto
{
    public Guid UserId { get; set; }
    /// <summary>null means "free workout" (no roadmap). Use Guid.Empty as sentinel in domain.</summary>
    public Guid? RoadmapId { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    public string ScheduledTime { get; set; } = string.Empty;
    public string Timezone { get; set; } = "UTC";
    public string SessionTitle { get; set; } = string.Empty;
    public string SessionType { get; set; } = "Strength";
    public int EstimatedDurationMinutes { get; set; }
    public bool NotificationEnabled { get; set; }
    public int NotificationMinutesBefore { get; set; } = 30;
    public List<CreateExecutionBlockDto> ExecutionBlocks { get; set; } = [];
}

/// <summary>
/// Custom Flow — User schedules a date/time for an existing UserCustomWorkout.
/// The backend copies CustomBlocks → ExecutionBlocks automatically.
/// </summary>
public class ScheduleFromCustomWorkoutDto
{
    public Guid UserId { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    public string ScheduledTime { get; set; } = string.Empty;
    public string Timezone { get; set; } = "UTC";
    public string SessionType { get; set; } = "Strength";
    public int EstimatedDurationMinutes { get; set; }
    public bool NotificationEnabled { get; set; }
    public int NotificationMinutesBefore { get; set; } = 30;
}

public class CreateExecutionBlockDto
{
    public int Order { get; set; }
    public Guid ExerciseId { get; set; }
    public string ExerciseName { get; set; } = string.Empty;
    public Guid? ExerciseAssetId { get; set; }
    public int TargetSets { get; set; }
    public int TargetReps { get; set; }
    public decimal TargetWeightKg { get; set; }
    public int RestSeconds { get; set; }
    public string Tempo { get; set; } = string.Empty;
    public string? ExerciseNotes { get; set; }
}

public class CreateRoadmapSessionDto
{
    public Guid RoadmapId { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    public string ScheduledTime { get; set; } = string.Empty;
    public string Timezone { get; set; } = string.Empty;
    public string SessionType { get; set; } = string.Empty;
    public string SessionTitle { get; set; } = string.Empty;
    public int EstimatedDurationMinutes { get; set; }
    public int EnergyDemandScore { get; set; }
    public int RecoveryRequirementScore { get; set; }
    public bool NotificationEnabled { get; set; }
    public int NotificationMinutesBefore { get; set; }
    public bool AiGenerated { get; set; }
    public SessionStatus SessionStatus { get; set; } = SessionStatus.Scheduled;
    public List<CreateExecutionBlockDto> ExecutionBlocks { get; set; } = [];
}

public class UpdateRoadmapSessionDto
{
    public Guid RoadmapId { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    public string ScheduledTime { get; set; } = string.Empty;
    public string Timezone { get; set; } = string.Empty;
    public string SessionType { get; set; } = string.Empty;
    public string SessionTitle { get; set; } = string.Empty;
    public int EstimatedDurationMinutes { get; set; }
    public int EnergyDemandScore { get; set; }
    public int RecoveryRequirementScore { get; set; }
    public bool NotificationEnabled { get; set; }
    public int NotificationMinutesBefore { get; set; }
    public bool AiGenerated { get; set; }
    public SessionStatus SessionStatus { get; set; }
    public List<CreateExecutionBlockDto> ExecutionBlocks { get; set; } = [];
}

/// <summary>Adaptive Engine — bulk adjust upcoming session volume/load.</summary>
public class ApplyTrainingAdjustmentRequestDto
{
    /// <summary>deload | progress | hold | substitute</summary>
    public string Decision { get; set; } = "hold";

    /// <summary>Volume % delta (e.g. -30 deload). Progress may use as load % if set.</summary>
    public double VolumeDeltaPct { get; set; }

    public double? EtaWeeks { get; set; }

    public string? Phase { get; set; }
}

public class ApplyTrainingAdjustmentResultDto
{
    public Guid UserId { get; set; }
    public string Decision { get; set; } = "hold";
    public double VolumeDeltaPct { get; set; }
    public int SessionsAdjusted { get; set; }
    public List<Guid> SessionIds { get; set; } = [];
    public string? Phase { get; set; }
    public double? EtaWeeks { get; set; }
    public string Status { get; set; } = "noop";
    public string Message { get; set; } = string.Empty;
}

