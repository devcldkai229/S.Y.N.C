using MongoDB.Bson.Serialization.Attributes;

namespace Social.Domain.Models;

public class Comment : BaseMongoEntity
{
    public Guid PostId { get; set; }

    public Guid UserId { get; set; }

    public string Content { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public AuthorSnapshot? AuthorSnapshot { get; set; }

    [BsonIgnoreIfNull]
    public Guid? ParentCommentId { get; set; }
}
