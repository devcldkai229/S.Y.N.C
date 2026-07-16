using Notification.Domain.Models;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushScheduleRepository
{
    Task<IReadOnlyList<SmartPushSchedule>> ClaimDueAsync(DateTimeOffset utcNow, int limit, CancellationToken ct);
    Task<SmartPushSchedule?> GetAsync(Guid userId, CancellationToken ct);
    Task UpsertAsync(SmartPushSchedule schedule, CancellationToken ct);
    Task UpsertManyAsync(IEnumerable<SmartPushSchedule> schedules, CancellationToken ct);
    Task<bool> TryInsertLogAsync(SmartPushLog log, CancellationToken ct);
    Task<bool> HasDedupKeyAsync(string dedupKey, CancellationToken ct);
    Task<DateTimeOffset?> GetLastTriggerSentAtAsync(Guid userId, string trigger, CancellationToken ct);
}
