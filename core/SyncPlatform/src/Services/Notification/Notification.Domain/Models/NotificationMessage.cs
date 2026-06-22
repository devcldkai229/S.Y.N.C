using MongoDB.Bson.Serialization.Attributes;
using Notification.Domain.Models;
using Notification.Domain.Enums;

namespace Notification.Domain.Models;

public class NotificationMessage : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public NotificationType Type { get; set; }

    public NotificationChannel Channel { get; set; }

    public NotificationPriority Priority { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Body { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? ImageUrl { get; set; }

    [BsonIgnoreIfNull]
    public string? DeepLink { get; set; }

    [BsonIgnoreIfNull]
    public string? DataPayloadJson { get; set; }

    [BsonIgnoreIfNull]
    public string? AiContextSnapshotJson { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? ScheduledFor { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? SentAt { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? DeliveredAt { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? ReadAt { get; set; }

    public NotificationStatus Status { get; set; }

    [BsonIgnoreIfNull]
    public string? ErrorMessage { get; set; }

    [BsonIgnoreIfNull]
    public string? SmartPushTopic { get; set; }

    [BsonIgnoreIfNull]
    public string? SmartPushDecisionCode { get; set; }

    [BsonIgnoreIfNull]
    public string? UserLocalDate { get; set; }
}
