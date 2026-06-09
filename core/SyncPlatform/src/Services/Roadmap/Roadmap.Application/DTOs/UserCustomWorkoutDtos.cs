using Libs.Shared.Enums;

namespace Roadmap.Application.DTOs;

public class UserCustomWorkoutDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string WorkoutName { get; set; } = string.Empty;
    public Visibility Visibility { get; set; }
    public Guid? ParentWorkoutId { get; set; }
    public int SavesCount { get; set; }
    public string ScheduleMode { get; set; } = string.Empty;
    public bool AllowAiOptimization { get; set; }
    public List<CustomBlockDto> CustomBlocks { get; set; } = [];
    public List<WorkoutSessionDto> Sessions { get; set; } = [];
    public DateTimeOffset CreatedAt { get; set; }
}

public class CustomBlockDto
{
    public Guid ExerciseId { get; set; }
    public int Sets { get; set; }
    public int Reps { get; set; }
    public decimal WeightKg { get; set; }
    public int RestSeconds { get; set; }
}

public class CreateUserCustomWorkoutDto
{
    public Guid UserId { get; set; }
    public string WorkoutName { get; set; } = string.Empty;
    public string ScheduleMode { get; set; } = string.Empty;
    public Visibility Visibility { get; set; } = Visibility.Private;
    public bool AllowAiOptimization { get; set; }
    public List<CreateCustomBlockDto> CustomBlocks { get; set; } = [];
}

public class CreateCustomBlockDto
{
    public Guid ExerciseId { get; set; }
    public int Sets { get; set; }
    public int Reps { get; set; }
    public decimal WeightKg { get; set; }
    public int RestSeconds { get; set; }
}

public class UpdateUserCustomWorkoutDto
{
    public string WorkoutName { get; set; } = string.Empty;
    public string ScheduleMode { get; set; } = string.Empty;
    public Visibility Visibility { get; set; }
    public bool AllowAiOptimization { get; set; }
    public List<CreateCustomBlockDto> CustomBlocks { get; set; } = [];
}

public class MyWorkoutDetailDto
{
    public Guid Id { get; set; }
    public string WorkoutName { get; set; } = string.Empty;
    public Visibility Visibility { get; set; }
    public Guid? ParentWorkoutId { get; set; }
    public int SavesCount { get; set; }
    public string ScheduleMode { get; set; } = string.Empty;
    public bool AllowAiOptimization { get; set; }
    public List<WorkoutSessionDto> Sessions { get; set; } = [];
    public List<ScheduledWorkoutDto> WeeklySchedules { get; set; } = [];
}

public class WorkoutSessionDto
{
    public Guid Id { get; set; }
    public string SessionTitle { get; set; } = string.Empty;
    public int ExerciseCount { get; set; }
    public int TotalSetCount { get; set; }
}

