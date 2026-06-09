namespace Roadmap.Application.DTOs;

public class CreateExerciseSetLogDto
{
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

public class UpdateExerciseSetLogDto
{
    public int ActualReps { get; set; }
    public double WeightKg { get; set; }
    public int Rir { get; set; }
    public int RestTakenSeconds { get; set; }
    public int FormScore { get; set; }
    public bool Completed { get; set; }
}
