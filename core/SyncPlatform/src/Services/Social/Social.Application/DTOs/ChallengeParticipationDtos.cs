using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class ChallengeParticipantDto
{
    public Guid UserId { get; set; }
    public ParticipantStatus Status { get; set; }
    public DateTimeOffset JoinedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public bool IsActive { get; set; }
}

public class UserChallengeDto
{
    public CommunityChallengeDto Challenge { get; set; } = new();
    public ParticipantStatus ParticipantStatus { get; set; }
    public DateTimeOffset JoinedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public bool IsActive { get; set; }
}

public class ChallengeParticipationStatusDto
{
    public bool HasJoined { get; set; }
    public ParticipantStatus? Status { get; set; }
}

public class ChallengeParticipantListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class UserChallengeListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
