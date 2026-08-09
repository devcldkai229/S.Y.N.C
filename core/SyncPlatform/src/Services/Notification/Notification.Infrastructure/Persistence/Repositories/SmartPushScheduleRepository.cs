using Microsoft.EntityFrameworkCore;
using Notification.Application.Services.SmartPush;
using Notification.Domain.Models;
using Notification.Infrastructure.Persistence;

namespace Notification.Infrastructure.Persistence.Repositories;

public class SmartPushScheduleRepository : ISmartPushScheduleRepository
{
    private readonly SmartPushDbContext _db;

    public SmartPushScheduleRepository(SmartPushDbContext db) => _db = db;

    public async Task<IReadOnlyList<SmartPushSchedule>> ClaimDueAsync(
        DateTimeOffset utcNow, int limit, CancellationToken ct)
    {
        // Postgres claim: FOR UPDATE SKIP LOCKED
        var sql = """
            SELECT user_id, enabled, timezone, next_fire_at_utc, slots_per_day, sent_today,
                   day_key_local, last_sent_at_utc, last_trigger, updated_at
            FROM smart_push.smart_push_schedule
            WHERE enabled = TRUE
              AND next_fire_at_utc IS NOT NULL
              AND next_fire_at_utc <= {0}
            ORDER BY next_fire_at_utc
            FOR UPDATE SKIP LOCKED
            LIMIT {1}
            """;

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var claimed = await _db.SmartPushSchedules
            .FromSqlRaw(sql, utcNow, limit)
            .AsTracking()
            .ToListAsync(ct);

        // Push next_fire a bit forward so another worker won't reclaim until we finish.
        foreach (var row in claimed)
        {
            row.NextFireAtUtc = utcNow.AddMinutes(2);
            row.UpdatedAt = DateTimeOffset.UtcNow;
        }

        if (claimed.Count > 0)
            await _db.SaveChangesAsync(ct);

        await tx.CommitAsync(ct);
        return claimed;
    }

    public Task<SmartPushSchedule?> GetAsync(Guid userId, CancellationToken ct) =>
        _db.SmartPushSchedules.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == userId, ct);

    public async Task UpsertAsync(SmartPushSchedule schedule, CancellationToken ct)
    {
        var existing = await _db.SmartPushSchedules.FirstOrDefaultAsync(x => x.UserId == schedule.UserId, ct);
        if (existing is null)
        {
            _db.SmartPushSchedules.Add(schedule);
        }
        else
        {
            existing.Enabled = schedule.Enabled;
            existing.Timezone = schedule.Timezone;
            existing.NextFireAtUtc = schedule.NextFireAtUtc;
            existing.SlotsPerDay = schedule.SlotsPerDay;
            existing.SentToday = schedule.SentToday;
            existing.DayKeyLocal = schedule.DayKeyLocal;
            existing.LastSentAtUtc = schedule.LastSentAtUtc;
            existing.LastTrigger = schedule.LastTrigger;
            existing.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task UpsertManyAsync(IEnumerable<SmartPushSchedule> schedules, CancellationToken ct)
    {
        foreach (var schedule in schedules)
            await UpsertAsync(schedule, ct);
    }

    public async Task<bool> TryInsertLogAsync(SmartPushLog log, CancellationToken ct)
    {
        try
        {
            _db.SmartPushLogs.Add(log);
            await _db.SaveChangesAsync(ct);
            return true;
        }
        catch (DbUpdateException)
        {
            _db.ChangeTracker.Clear();
            return false;
        }
    }

    public Task<bool> HasDedupKeyAsync(string dedupKey, CancellationToken ct) =>
        _db.SmartPushLogs.AsNoTracking().AnyAsync(x => x.DedupKey == dedupKey, ct);

    public async Task<DateTimeOffset?> GetLastTriggerSentAtAsync(Guid userId, string trigger, CancellationToken ct)
    {
        return await _db.SmartPushLogs.AsNoTracking()
            .Where(x => x.UserId == userId && x.Trigger == trigger)
            .OrderByDescending(x => x.SentAtUtc)
            .Select(x => (DateTimeOffset?)x.SentAtUtc)
            .FirstOrDefaultAsync(ct);
    }
}
