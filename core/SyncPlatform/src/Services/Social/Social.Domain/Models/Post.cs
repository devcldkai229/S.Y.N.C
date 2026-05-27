using MongoDB.Bson.Serialization.Attributes;
using Social.Domain.Enums;

namespace Social.Domain.Models;

public class Post : BaseMongoEntity
{
    public Guid AuthorId { get; set; }

    public AuthorSnapshot AuthorSnapshot { get; set; } = new();

    public PostType PostType { get; set; } = PostType.Standard;

    public string Content { get; set; } = string.Empty;

    public List<string> MediaUrls { get; set; } = [];

    [BsonIgnoreIfNull]
    public Guid? ReferenceId { get; set; }

    public PostMetrics Metrics { get; set; } = new();

    /// <summary>
    /// When true, post is visible on community feed; when false, author-only / friends logic (app layer).
    /// </summary>
    public bool IsPublic { get; set; } = true;

    /// <summary>Unique 8-char code for deep links (GET /posts/share/{shareCode}).</summary>
    public string ShareCode { get; set; } = string.Empty;
}
