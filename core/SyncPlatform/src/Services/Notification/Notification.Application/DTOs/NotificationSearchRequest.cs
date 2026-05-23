using Notification.Domain.Enums;

namespace Notification.Application.DTOs;

public class NotificationSearchRequest
{
    public NotificationStatus? Status { get; set; }
    public NotificationChannel? Channel { get; set; }
    public NotificationType? Type { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
