using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class SocialUserSearchRequest
{
    public string Query { get; set; } = string.Empty;

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class SocialUserSearchItemDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    public FollowStatus? OutgoingStatus { get; set; }

    public bool CanFollow { get; set; }
}
