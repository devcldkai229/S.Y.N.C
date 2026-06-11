using Social.Domain.Enums;

namespace Social.Domain.Models;

public class UserFollow : BaseMongoEntity
{
    public Guid FollowerId { get; set; }

    public Guid FolloweeId { get; set; }

    public DateTimeOffset FollowedAt { get; set; } = DateTimeOffset.UtcNow;

    public FollowStatus Status { get; set; } = FollowStatus.Accepted;
}
