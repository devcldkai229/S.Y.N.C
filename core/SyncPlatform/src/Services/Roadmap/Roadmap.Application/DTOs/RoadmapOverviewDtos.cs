namespace Roadmap.Application.DTOs;

public class RoadmapOverviewDto
{
    public Guid RoadmapId { get; set; }
    public string RoadmapName { get; set; } = string.Empty;
    public string FitnessGoal { get; set; } = string.Empty;
    public int CurrentWeek { get; set; }
    public int TotalWeeks { get; set; }
    public IReadOnlyList<PhaseOverviewDto> Phases { get; set; } = [];
    public string PhaseRationaleVi { get; set; } = string.Empty;
    public string PhaseRationaleEn { get; set; } = string.Empty;
    public ProgressOverviewDto Progress { get; set; } = new();
    public ReadinessOverviewDto? Readiness { get; set; }
    public IReadOnlyList<SessionOverviewDto> Sessions { get; set; } = [];
}

public class PhaseOverviewDto
{
    public string Key { get; set; } = string.Empty;
    public string DisplayNameVi { get; set; } = string.Empty;
    public string DisplayNameEn { get; set; } = string.Empty;
    /// <summary>Done | Current | Upcoming</summary>
    public string Status { get; set; } = "Upcoming";
    public int WeekFrom { get; set; }
    public int WeekTo { get; set; }
}

public class ProgressOverviewDto
{
    /// <summary>Progress within the current phase (0–100).</summary>
    public int PhasePercent { get; set; }
    public decimal? CurrentWeightKg { get; set; }
    public decimal? TargetWeightKg { get; set; }
}

public class ReadinessOverviewDto
{
    /// <summary>Ready | Moderate | Rest</summary>
    public string Level { get; set; } = "Moderate";
    public int Score { get; set; }
    public int Fatigue { get; set; }
    public int Soreness { get; set; }
    public string AiAdjustmentNoteVi { get; set; } = string.Empty;
    public string AiAdjustmentNoteEn { get; set; } = string.Empty;
}

public class SessionOverviewDto
{
    public Guid Id { get; set; }
    public string DisplayNameVi { get; set; } = string.Empty;
    public string SubtitleEn { get; set; } = string.Empty;
    /// <summary>Scheduled | Completed | Skipped | InProgress</summary>
    public string Status { get; set; } = string.Empty;
    public int DurationMin { get; set; }
    public int ExerciseCount { get; set; }
    public string? ScheduledTime { get; set; }
    public DateTimeOffset ScheduledDate { get; set; }
    /// <summary>Light | Moderate | High</summary>
    public string Intensity { get; set; } = "Moderate";
    public bool IsAi { get; set; }
    public string RationaleVi { get; set; } = string.Empty;
    public string RationaleEn { get; set; } = string.Empty;
    public bool IsNextUp { get; set; }
}
