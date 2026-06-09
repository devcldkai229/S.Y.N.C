namespace Roadmap.Application.DTOs;

public class WorkoutExecutionLogDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public int ActualDurationMinutes { get; set; }
    public int PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
    public int CaloriesBurned { get; set; }
    public int CompletionRate { get; set; }
    public string? AiCoachFeedback { get; set; }
    public List<Guid> SkippedExercises { get; set; } = [];
    public string? SessionFeedback { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreateWorkoutExecutionLogDto
{
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public int ActualDurationMinutes { get; set; }
    public int PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
    public int CaloriesBurned { get; set; }
    public int CompletionRate { get; set; }
    public string? AiCoachFeedback { get; set; }
    public List<Guid> SkippedExercises { get; set; } = [];
    public string? SessionFeedback { get; set; }
}

public class UpdateWorkoutExecutionLogDto
{
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public int ActualDurationMinutes { get; set; }
    public int PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
    public int CaloriesBurned { get; set; }
    public int CompletionRate { get; set; }
    public string? AiCoachFeedback { get; set; }
    public List<Guid> SkippedExercises { get; set; } = [];
    public string? SessionFeedback { get; set; }
}
