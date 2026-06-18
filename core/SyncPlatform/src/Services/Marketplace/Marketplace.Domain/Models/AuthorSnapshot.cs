using MongoDB.Bson.Serialization.Attributes;

namespace Marketplace.Domain.Models;

/// <summary>
/// Denormalized author display data (mirrors Social.Domain.Models.AuthorSnapshot).
/// </summary>
public class AuthorSnapshot
{
    public string FullName { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? AvatarUrl { get; set; }
}
