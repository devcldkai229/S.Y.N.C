using Libs.Shared.Enums;

namespace Exercise.Application.DTOs;

public class WorkoutTemplateDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Goal { get; set; } = string.Empty;
    public Difficulty Difficulty { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public List<string> TargetMuscleGroups { get; set; } = [];
    public List<string> RequiredEquipment { get; set; } = [];
    public int EstimatedCaloriesBurn { get; set; }
    public int AiRecoveryScore { get; set; }
    public bool IsSystemTemplate { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public List<TemplateSessionBlockDto> Sessions { get; set; } = [];
}

public class TemplateSessionBlockDto
{
    public int Order { get; set; }
    public Guid ExerciseId { get; set; }
    public int Sets { get; set; }
    public int MinReps { get; set; }
    public int MaxReps { get; set; }
    public int RestSeconds { get; set; }
    public string Tempo { get; set; } = string.Empty;
    public int Rir { get; set; }
    public string? Notes { get; set; }
}

public class CreateWorkoutTemplateDto
{
    public string Name { get; set; } = string.Empty;
    public string Goal { get; set; } = string.Empty;
    public Difficulty Difficulty { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public int EstimatedCaloriesBurn { get; set; }
    public int AiRecoveryScore { get; set; }
    public bool IsSystemTemplate { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public List<TemplateSessionBlockDto> Sessions { get; set; } = [];
}

public class UpdateWorkoutTemplateDto : CreateWorkoutTemplateDto
{
}
