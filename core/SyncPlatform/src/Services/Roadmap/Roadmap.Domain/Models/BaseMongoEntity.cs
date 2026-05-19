using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Roadmap.Domain.Models;

public abstract class BaseMongoEntity
{
    [BsonId]
    [BsonRepresentation(BsonType.String)]
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    [BsonIgnoreIfNull]
    public DateTimeOffset? UpdatedAt { get; set; }
}
