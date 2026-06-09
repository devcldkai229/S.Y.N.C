using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class AuthorSnapshotDto
{
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
}

public class PostMetricsDto
{
    public int LikeCount { get; set; }
    public int CommentCount { get; set; }
    public int ShareCount { get; set; }
}

public class PostDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
    public Guid AuthorId { get; set; }
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
    public PostType PostType { get; set; }
    public string Content { get; set; } = string.Empty;
    public IReadOnlyList<string> MediaUrls { get; set; } = [];
    public Guid? ReferenceId { get; set; }
    public PostMetricsDto Metrics { get; set; } = new();
    public bool IsPublic { get; set; }
    public string ShareCode { get; set; } = string.Empty;
    public bool IsLikedByMe { get; set; }
}

public class CreatePostDto
{
    public PostType PostType { get; set; } = PostType.Standard;
    public string Content { get; set; } = string.Empty;
    public List<string> MediaUrls { get; set; } = [];
    public Guid? ReferenceId { get; set; }
    public bool IsPublic { get; set; } = true;
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
}

public class PostFeedQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
