using MongoDB.Bson.Serialization.Attributes;
using Libs.Shared.Enums;

namespace Exercise.Domain.Models;

public class WorkoutTemplate : BaseMongoEntity
{
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

    public List<TemplateSessionBlock> Sessions { get; set; } = [];

    public class TemplateSessionBlock
    {
        public int Order { get; set; }

        public Guid ExerciseId { get; set; }

        public int Sets { get; set; }

        public int MinReps { get; set; }

        public int MaxReps { get; set; }

        public int RestSeconds { get; set; }

        public string Tempo { get; set; } = string.Empty;

        public int Rir { get; set; }

        [BsonIgnoreIfNull]
        public string? Notes { get; set; }
    }
}
