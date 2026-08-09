using MongoDB.Bson.Serialization.Attributes;

namespace Social.Domain.Models;

public class BlogComment : BaseMongoEntity
{
    public Guid BlogId { get; set; }

    public Guid UserId { get; set; }

    public string Content { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public AuthorSnapshot? AuthorSnapshot { get; set; }
}
