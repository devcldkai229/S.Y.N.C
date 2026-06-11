using MongoDB.Bson.Serialization.Attributes;
using Social.Domain.Enums;

namespace Social.Domain.Models;

public class ChallengeParticipant : BaseMongoEntity
{
    public Guid ChallengeId { get; set; }

    public Guid UserId { get; set; }

    public ParticipantStatus Status { get; set; } = ParticipantStatus.Joined;

    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;

    [BsonIgnoreIfNull]
    public DateTimeOffset? CompletedAt { get; set; }

    /// <summary>
    /// Đánh dấu user có bỏ cuộc giữa chừng không
    /// </summary>
    public bool IsActive { get; set; } = true;
}