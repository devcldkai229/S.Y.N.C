using MongoDB.Bson.Serialization.Attributes;
using Social.Domain.Enums;

namespace Social.Domain.Models;

public class Story : BaseMongoEntity
{
    public Guid AuthorId { get; set; }

    public AuthorSnapshot AuthorSnapshot { get; set; } = new();

    public string MediaUrl { get; set; } = string.Empty;

    public StoryMediaType MediaType { get; set; } = StoryMediaType.TextOnly;

    [BsonIgnoreIfNull]
    public string? Caption { get; set; }

    public DateTimeOffset ExpiresAt { get; set; }

    public int ViewCount { get; set; }

    public int LikeCount { get; set; }

    public bool IsActive { get; set; } = true;

    public PrivacyType Privacy { get; set; } = PrivacyType.Public;
}