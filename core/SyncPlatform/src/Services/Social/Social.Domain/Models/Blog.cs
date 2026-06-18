using MongoDB.Bson.Serialization.Attributes;
using Social.Domain.Enums;

namespace Social.Domain.Models;

public class Blog : BaseMongoEntity
{
    public Guid AuthorId { get; set; }

    public AuthorSnapshot AuthorSnapshot { get; set; } = new();

    public string Title { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string CoverImageUrl { get; set; } = string.Empty;

    public string[]? MediaUrls { get; set; } = [];

    public string Content { get; set; } = string.Empty;

    public List<string> Tags { get; set; } = [];

    public BlogStatus Status { get; set; } = BlogStatus.Draft;

    [BsonIgnoreIfNull]
    public DateTimeOffset? PublishedAt { get; set; }

    public int LikeCount { get; set; } = 0;

    public int ShareCount { get; set; } = 0;
}