using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class BlogDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
    public Guid AuthorId { get; set; }
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public IReadOnlyList<string> MediaUrls { get; set; } = [];
    public string Content { get; set; } = string.Empty;
    public IReadOnlyList<string> Tags { get; set; } = [];
    public BlogStatus Status { get; set; }
    public DateTimeOffset? PublishedAt { get; set; }
    public int LikeCount { get; set; }
    public int ShareCount { get; set; }
    public bool IsLikedByMe { get; set; }
}

public class CreateBlogDto
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public List<string> MediaUrls { get; set; } = [];
    public List<string> Tags { get; set; } = [];
    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();
}

public class UpdateBlogDto
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public List<string> MediaUrls { get; set; } = [];
    public List<string> Tags { get; set; } = [];
}

public class BlogListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? Tag { get; set; }
}

public class BlogEngagementResultDto
{
    public Guid BlogId { get; set; }
    public int LikeCount { get; set; }
    public int ShareCount { get; set; }
}
