namespace Notification.Domain.Models;

/// <summary>Audit + idempotency log for Smart Push sends.</summary>
public class SmartPushLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTimeOffset SentAtUtc { get; set; } = DateTimeOffset.UtcNow;
    public DateOnly LocalDate { get; set; }
    public string Trigger { get; set; } = string.Empty;
    public string DedupKey { get; set; } = string.Empty;
    public string Channel { get; set; } = "inapp";
    public string? Title { get; set; }
    public string? Body { get; set; }
    public bool Opened { get; set; }
}
