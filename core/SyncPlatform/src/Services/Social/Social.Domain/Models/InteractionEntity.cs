using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Social.Domain.Models;

/// <summary>
/// Lightweight base for interaction records (no UpdatedAt).
/// </summary>
public abstract class InteractionEntity
{
    [BsonId]
    [BsonRepresentation(BsonType.String)]
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
