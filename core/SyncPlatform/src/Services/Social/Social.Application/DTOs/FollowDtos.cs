using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class FollowListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class UserFollowDto
{
    public Guid Id { get; set; }
    public Guid FollowerId { get; set; }
    public Guid FolloweeId { get; set; }
    public FollowStatus Status { get; set; }
    public DateTimeOffset FollowedAt { get; set; }
}

public class FollowCountsDto
{
    public Guid UserId { get; set; }
    public int FollowerCount { get; set; }
    public int FollowingCount { get; set; }
}

/// <summary>
/// Relationship from the viewer to the target user.
/// </summary>
public class FollowStatusDto
{
    public Guid ViewerUserId { get; set; }
    public Guid TargetUserId { get; set; }

    /// <summary>None, Pending (outgoing), Accepted, or Blocked from viewer perspective.</summary>
    public FollowStatus? OutgoingStatus { get; set; }

    /// <summary>Pending when the target has requested to follow the viewer.</summary>
    public bool HasIncomingPendingRequest { get; set; }

    public bool IsBlockedBetween { get; set; }

    public bool CanFollow { get; set; }

    public bool CanViewContent { get; set; }
}
