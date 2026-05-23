using Notification.Domain.Enums;

namespace Notification.Application.DTOs;

public class NotificationMessageDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public NotificationType Type { get; set; }
    public NotificationChannel Channel { get; set; }
    public NotificationPriority Priority { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? DeepLink { get; set; }
    public string? DataPayloadJson { get; set; }
    public string? AiContextSnapshotJson { get; set; }
    public DateTimeOffset? ScheduledFor { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public DateTimeOffset? DeliveredAt { get; set; }
    public DateTimeOffset? ReadAt { get; set; }
    public NotificationStatus Status { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}
