using Libs.Shared.Enums;

namespace Roadmap.Application.DTOs;

public class ScheduledWorkoutDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset ScheduledStartTime { get; set; }
    public DateTimeOffset ScheduledEndTime { get; set; }
    public SessionStatus Status { get; set; }
    public string RepeatPattern { get; set; } = string.Empty;
}

/// <summary>
/// Combined result returned by both ScheduleAsync and ScheduleFromCustomWorkoutAsync.
/// Contains the created Session + its corresponding ScheduledWorkout calendar entry.
/// </summary>
public class ScheduledSessionResultDto
{
    public RoadmapSessionDto Session { get; set; } = null!;
    public ScheduledWorkoutDto ScheduledWorkout { get; set; } = null!;
}

public class CreateScheduledWorkoutDto
{
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset ScheduledStartTime { get; set; }
    public DateTimeOffset ScheduledEndTime { get; set; }
    public SessionStatus Status { get; set; } = SessionStatus.Scheduled;
    public string RepeatPattern { get; set; } = string.Empty;
}

public class UpdateScheduledWorkoutDto
{
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset ScheduledStartTime { get; set; }
    public DateTimeOffset ScheduledEndTime { get; set; }
    public SessionStatus Status { get; set; }
    public string RepeatPattern { get; set; } = string.Empty;
}

