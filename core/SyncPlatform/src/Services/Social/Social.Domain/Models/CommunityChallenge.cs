using Social.Domain.Enums;

namespace Social.Domain.Models;

public class CommunityChallenge : BaseMongoEntity
{
    public Guid CreatorId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public DateTimeOffset StartDate { get; set; }

    public DateTimeOffset EndDate { get; set; }

    public ChallengeGoalType GoalType { get; set; }

    public decimal TargetValue { get; set; }

    public int ParticipantCount { get; set; }

    public ChallengeStatus Status { get; set; }
}
