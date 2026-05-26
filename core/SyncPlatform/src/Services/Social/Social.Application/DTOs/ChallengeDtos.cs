using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class CommunityChallengeDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
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

public class CreateCommunityChallengeDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset StartDate { get; set; }
    public DateTimeOffset EndDate { get; set; }
    public ChallengeGoalType GoalType { get; set; }
    public decimal TargetValue { get; set; }

    /// <summary>Displayed on the auto-generated feed post.</summary>
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();

    /// <summary>Optional custom feed text; generated from title if empty.</summary>
    public string? FeedAnnouncement { get; set; }
}
