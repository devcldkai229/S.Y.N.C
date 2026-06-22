namespace Notification.Domain.Enums;

public enum NotificationStatus
{
    Pending = 0,
    Sent = 1,
    Delivered = 2,
    Read = 3,
    Failed = 4,
    Cancelled = 5,
    Processing = 6
}
