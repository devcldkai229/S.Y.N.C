using System.Text.Json.Serialization;

namespace Social.SeedTool.Models;

public sealed class SocialSeedFile
{
    public List<PostSeedDto> Posts { get; set; } = [];

    public List<CommentSeedDto> Comments { get; set; } = [];

    public List<InteractionSeedDto> Interactions { get; set; } = [];

    public List<UserFollowSeedDto> UserFollows { get; set; } = [];
}

public sealed class AuthorSnapshotSeedDto
{
    public string FullName { get; set; } = string.Empty;

    [JsonIgnore]
    public string? AvatarUrl { get; set; }
}

public sealed class PostMetricsSeedDto
{
    public int LikeCount { get; set; }

    public int CommentCount { get; set; }

    public int ShareCount { get; set; }
}

public sealed class PostSeedDto
{
    public Guid Id { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public Guid AuthorId { get; set; }

    public AuthorSnapshotSeedDto AuthorSnapshot { get; set; } = new();

    public string PostType { get; set; } = "Standard";

    public string Content { get; set; } = string.Empty;

    public List<string> MediaUrls { get; set; } = [];

    public Guid? ReferenceId { get; set; }

    public PostMetricsSeedDto Metrics { get; set; } = new();

    public bool IsPublic { get; set; } = true;

    public string ShareCode { get; set; } = string.Empty;
}

public sealed class CommentSeedDto
{
    public Guid Id { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public Guid PostId { get; set; }

    public Guid UserId { get; set; }

    public string Content { get; set; } = string.Empty;

    public AuthorSnapshotSeedDto? AuthorSnapshot { get; set; }

    public Guid? ParentCommentId { get; set; }
}

public sealed class InteractionSeedDto
{
    public Guid Id { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public Guid PostId { get; set; }

    public Guid UserId { get; set; }

    public string InteractionType { get; set; } = "Like";
}

public sealed class UserFollowSeedDto
{
    public Guid Id { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public Guid FollowerId { get; set; }

    public Guid FolloweeId { get; set; }

    public DateTimeOffset FollowedAt { get; set; }

    public string Status { get; set; } = "Accepted";
}
