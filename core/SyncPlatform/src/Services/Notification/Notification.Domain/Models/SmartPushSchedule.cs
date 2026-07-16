namespace Notification.Domain.Models;

/// <summary>System-owned next-fire schedule for Smart Push (Postgres).</summary>
public class SmartPushSchedule
{
    public Guid UserId { get; set; }
    public bool Enabled { get; set; } = true;
    public string Timezone { get; set; } = "Asia/Ho_Chi_Minh";
    public DateTimeOffset? NextFireAtUtc { get; set; }
    public short SlotsPerDay { get; set; } = 2;
    public short SentToday { get; set; }
    public DateOnly? DayKeyLocal { get; set; }
    public DateTimeOffset? LastSentAtUtc { get; set; }
    public string? LastTrigger { get; set; }
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
