using MongoDB.Bson.Serialization.Attributes;
using Roadmap.Domain.Models;

namespace Roadmap.Domain.Models;

public class WorkoutExecutionLog : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public Guid SessionId { get; set; }

    public DateTimeOffset StartedAt { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? CompletedAt { get; set; }

    public int ActualDurationMinutes { get; set; }

    public int PerceivedDifficulty { get; set; }

    public int EnergyLevelBefore { get; set; }

    public int EnergyLevelAfter { get; set; }

    public int CaloriesBurned { get; set; }

    public int CompletionRate { get; set; }

    [BsonIgnoreIfNull]
    public string? AiCoachFeedback { get; set; }

    public List<Guid> SkippedExercises { get; set; } = [];

    [BsonIgnoreIfNull]
    public string? SessionFeedback { get; set; }
}
