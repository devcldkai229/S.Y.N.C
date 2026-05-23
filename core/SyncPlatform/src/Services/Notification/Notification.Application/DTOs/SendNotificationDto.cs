using Notification.Domain.Enums;

namespace Notification.Application.DTOs;

public class SendNotificationDto
{
    public Guid UserId { get; set; }
    public NotificationType Type { get; set; }
    public NotificationChannel Channel { get; set; }
    public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? DeepLink { get; set; }
    public string? DataPayloadJson { get; set; }
    public string? AiContextSnapshotJson { get; set; }
    public DateTimeOffset? ScheduledFor { get; set; }
}
