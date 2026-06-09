using Libs.Shared.Enums;

namespace Roadmap.Domain.Models;

public class UserCustomWorkout : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public string WorkoutName { get; set; } = string.Empty;

    public Visibility Visibility { get; set; }

    public Guid? ParentWorkoutId { get; set; }

    public int SavesCount { get; set; }

    public string ScheduleMode { get; set; } = string.Empty;

    public bool AllowAiOptimization { get; set; }

    public List<CustomBlock> CustomBlocks { get; set; } = [];

    public class CustomBlock
    {
        public Guid ExerciseId { get; set; }

        public int Sets { get; set; }

        public int Reps { get; set; }

        public decimal WeightKg { get; set; }

        public int RestSeconds { get; set; }
    }
}
