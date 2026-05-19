using MongoDB.Bson.Serialization.Attributes;
using Notification.Domain.Models;
using Notification.Domain.Enums;

namespace Notification.Domain.Models;

public class NotificationTemplate : BaseMongoEntity
{
    public string TemplateCode { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string DefaultTitle { get; set; } = string.Empty;

    public string DefaultBody { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? VariablesJson { get; set; }

    public NotificationChannel Channel { get; set; }

    public bool IsActive { get; set; }
}
