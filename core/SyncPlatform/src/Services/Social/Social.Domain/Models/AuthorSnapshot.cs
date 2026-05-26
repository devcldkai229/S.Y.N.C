using MongoDB.Bson.Serialization.Attributes;

namespace Social.Domain.Models;

/// <summary>
/// Denormalized author display data at post creation time (avoids IAM join on feed load).
/// </summary>
public class AuthorSnapshot
{
    public string FullName { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? AvatarUrl { get; set; }
}
