using Marketplace.Domain.Enums;
using MongoDB.Bson.Serialization.Attributes;

namespace Marketplace.Domain.Models;

public class Review : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public AuthorSnapshot AuthorSnapshot { get; set; } = new();

    public ReviewTargetType TargetType { get; set; }

    public Guid TargetId { get; set; }

    public int Rating { get; set; }

    [BsonIgnoreIfNull]
    public string? Comment { get; set; }

    [BsonIgnoreIfNull]
    public List<string>? ImageUrls { get; set; }

    [BsonIgnoreIfNull]
    public Guid? OrderId { get; set; }

    public bool IsVerifiedPurchase { get; set; }

    [BsonIgnoreIfNull]
    public string? PartnerReply { get; set; }
}
