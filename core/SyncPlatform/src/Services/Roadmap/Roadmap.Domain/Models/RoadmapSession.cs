using MongoDB.Bson.Serialization.Attributes;
using Libs.Shared.Enums;

namespace Roadmap.Domain.Models;

public class RoadmapSession : BaseMongoEntity
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

    public List<ExecutionBlock> ExecutionBlocks { get; set; } = [];

    public class ExecutionBlock
    {
        public int Order { get; set; }

        public Guid ExerciseId { get; set; }

        public string ExerciseName { get; set; } = string.Empty;

        [BsonIgnoreIfNull]
        public Guid? ExerciseAssetId { get; set; }

        public int TargetSets { get; set; }

        public int TargetReps { get; set; }

        public decimal TargetWeightKg { get; set; }

        public int RestSeconds { get; set; }

        public string Tempo { get; set; } = string.Empty;

        [BsonIgnoreIfNull]
        public string? ExerciseNotes { get; set; }
    }
}
