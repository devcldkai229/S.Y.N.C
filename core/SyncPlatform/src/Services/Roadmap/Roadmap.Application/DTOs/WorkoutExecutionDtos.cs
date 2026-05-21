namespace Roadmap.Application.DTOs;

public class WorkoutExecutionResultDto
{
    public Guid ExecutionLogId { get; set; }
    public Guid SessionId { get; set; }
    public Guid UserId { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public int ActualDurationMinutes { get; set; }
    public int PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
    public int CaloriesBurned { get; set; }
    public int CompletionRate { get; set; }
    public List<Guid> SkippedExercises { get; set; } = [];
    public List<ExerciseSetLogDto> SetsPerformed { get; set; } = [];
}

public class ExerciseSetLogDto
{
    public Guid Id { get; set; }
    public Guid ExecutionId { get; set; }
    public Guid ExerciseId { get; set; }
    public int SetNumber { get; set; }
    public int TargetReps { get; set; }
    public int ActualReps { get; set; }
    public decimal WeightKg { get; set; }
    public int Rir { get; set; }
    public int RestTakenSeconds { get; set; }
    public int FormScore { get; set; }
    public bool Completed { get; set; }
}

public class SubmitWorkoutExecutionDto
{
    public Guid UserId { get; set; }
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public int PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
    public int CaloriesBurned { get; set; }
    public string? SessionFeedback { get; set; }
    public List<Guid> SkippedExercises { get; set; } = [];
    public List<SubmitSetDto> SetsPerformed { get; set; } = [];
}

public class SubmitSetDto
{
    public Guid ExerciseId { get; set; }
    public int SetNumber { get; set; }
    public int TargetReps { get; set; }
    public int ActualReps { get; set; }
    public decimal WeightKg { get; set; }
    public int Rir { get; set; }
    public int RestTakenSeconds { get; set; }
    public int FormScore { get; set; }
}
