using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class StoryDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public Guid AuthorId { get; set; }
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
    public string MediaUrl { get; set; } = string.Empty;
    public StoryMediaType MediaType { get; set; }
    public string? Caption { get; set; }
    public int ViewCount { get; set; }
    public int LikeCount { get; set; }
    public PrivacyType Privacy { get; set; }
    public bool IsLikedByMe { get; set; }
}

public class CreateStoryDto
{
    public string? Caption { get; set; }
    public PrivacyType Privacy { get; set; } = PrivacyType.Public;
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
}

public class StoryFeedGroupDto
{
    public Guid AuthorId { get; set; }
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
    public IReadOnlyList<StoryDto> Stories { get; set; } = [];
}

public class StoryViewResultDto
{
    public Guid StoryId { get; set; }
    public int ViewCount { get; set; }
    public bool IsFirstView { get; set; }
}

public class StoryLikeResultDto
{
    public Guid StoryId { get; set; }
    public int LikeCount { get; set; }
    public bool IsLikedByMe { get; set; } = true;
}
