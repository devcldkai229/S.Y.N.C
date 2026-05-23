using Notification.Domain.Enums;

namespace Notification.Application.DTOs;

public class SendTemplatedNotificationDto
{
    public Guid UserId { get; set; }
    public string TemplateCode { get; set; } = string.Empty;
    public Dictionary<string, string> Variables { get; set; } = new();
    public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;
    public string? DeepLink { get; set; }
    public string? AiContextSnapshotJson { get; set; }
    public DateTimeOffset? ScheduledFor { get; set; }
}
