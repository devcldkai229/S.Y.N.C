using Microsoft.Extensions.Options;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;
using Notification.Domain.Models;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushScheduleService
{
    DateTimeOffset? ComputeNextFire(
        SmartPushEnabledUserDto user,
        DateTimeOffset utcNow,
        SmartPushSchedule? existing);

    SmartPushSchedule BuildOrRefreshSchedule(
        SmartPushEnabledUserDto user,
        DateTimeOffset utcNow,
        SmartPushSchedule? existing);

    void MarkSent(SmartPushSchedule schedule, string trigger, DateTimeOffset utcNow);

    void RescheduleAfterSuppress(SmartPushSchedule schedule, DateTimeOffset utcNow, SmartPushEnabledUserDto user);
}

public class SmartPushScheduleService : ISmartPushScheduleService
{
    private readonly SmartPushOptions _options;

    public SmartPushScheduleService(IOptions<SmartPushOptions> options) => _options = options.Value;

    public SmartPushSchedule BuildOrRefreshSchedule(
        SmartPushEnabledUserDto user,
        DateTimeOffset utcNow,
        SmartPushSchedule? existing)
    {
        var enabled = user.SmartPushEnabled && user.AllowAiGeneratedNotification;
        var tz = ResolveTz(user.TimeZoneId);
        var localNow = TimeZoneInfo.ConvertTime(utcNow, tz);
        var dayKey = DateOnly.FromDateTime(localNow.DateTime);

        var schedule = existing ?? new SmartPushSchedule { UserId = user.UserId };
        schedule.Timezone = user.TimeZoneId;
        schedule.Enabled = enabled;
        schedule.SlotsPerDay = (short)Math.Clamp(_options.MaxPerDay, 1, 2);

        if (schedule.DayKeyLocal != dayKey)
        {
            schedule.SentToday = 0;
            schedule.DayKeyLocal = dayKey;
        }

        if (!enabled)
        {
            schedule.NextFireAtUtc = null;
            schedule.UpdatedAt = DateTimeOffset.UtcNow;
            return schedule;
        }

        schedule.NextFireAtUtc = ComputeNextFire(user, utcNow, schedule);
        schedule.UpdatedAt = DateTimeOffset.UtcNow;
        return schedule;
    }

    public void MarkSent(SmartPushSchedule schedule, string trigger, DateTimeOffset utcNow)
    {
        var tz = ResolveTz(schedule.Timezone);
        var localNow = TimeZoneInfo.ConvertTime(utcNow, tz);
        var dayKey = DateOnly.FromDateTime(localNow.DateTime);
        if (schedule.DayKeyLocal != dayKey)
        {
            schedule.SentToday = 0;
            schedule.DayKeyLocal = dayKey;
        }

        schedule.SentToday = (short)(schedule.SentToday + 1);
        schedule.LastSentAtUtc = utcNow;
        schedule.LastTrigger = trigger;
        schedule.UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void RescheduleAfterSuppress(SmartPushSchedule schedule, DateTimeOffset utcNow, SmartPushEnabledUserDto user)
    {
        schedule.NextFireAtUtc = ComputeNextFire(user, utcNow, schedule);
        schedule.UpdatedAt = DateTimeOffset.UtcNow;
    }

    public DateTimeOffset? ComputeNextFire(
        SmartPushEnabledUserDto user,
        DateTimeOffset utcNow,
        SmartPushSchedule? existing)
    {
        if (!(user.SmartPushEnabled && user.AllowAiGeneratedNotification))
            return null;

        var tz = ResolveTz(user.TimeZoneId);
        var windowStart = ParseTime(_options.WindowStartLocal, new TimeSpan(6, 0, 0));
        var windowEnd = ParseTime(_options.WindowEndLocal, new TimeSpan(20, 0, 0));
        var slotsPerDay = Math.Clamp(_options.MaxPerDay, 1, 2);
        var minGap = TimeSpan.FromHours(Math.Max(1, _options.MinGapHours));
        var jitter = TimeSpan.FromMinutes(Math.Max(0, _options.JitterMinutes));

        var localNow = TimeZoneInfo.ConvertTime(utcNow, tz);
        var today = DateOnly.FromDateTime(localNow.DateTime);
        var sentToday = existing?.DayKeyLocal == today ? existing.SentToday : (short)0;

        var slots = BuildLocalSlots(user, today, slotsPerDay, windowStart, windowEnd);
        var candidates = new List<DateTimeOffset>();
        foreach (var slotLocal in slots)
        {
            var asUtc = ToUtc(slotLocal, tz);
            if (asUtc <= utcNow.AddMinutes(1))
                continue;
            candidates.Add(asUtc);
        }

        DateTimeOffset next;
        if (candidates.Count == 0 || sentToday >= slotsPerDay)
        {
            var tomorrow = today.AddDays(1);
            var tomorrowSlots = BuildLocalSlots(user, tomorrow, slotsPerDay, windowStart, windowEnd);
            next = ToUtc(tomorrowSlots[0], tz);
        }
        else
        {
            next = candidates.Min();
        }

        // Jitter
        if (jitter > TimeSpan.Zero)
        {
            var deltaMinutes = Random.Shared.Next(-(int)jitter.TotalMinutes, (int)jitter.TotalMinutes + 1);
            next = next.AddMinutes(deltaMinutes);
            next = ClampToWindowUtc(next, tz, windowStart, windowEnd);
        }

        // Min gap from last sent
        if (existing?.LastSentAtUtc is { } lastSent)
        {
            var earliest = lastSent + minGap;
            if (next < earliest)
                next = earliest;
            next = ClampToWindowUtc(next, tz, windowStart, windowEnd);
            if (TimeZoneInfo.ConvertTime(next, tz).TimeOfDay < windowStart)
            {
                var local = TimeZoneInfo.ConvertTime(next, tz);
                var nextDay = DateOnly.FromDateTime(local.DateTime).AddDays(1);
                next = ToUtc(nextDay.ToDateTime(TimeOnly.FromTimeSpan(windowStart)), tz);
            }
        }

        return next;
    }

    private static List<DateTime> BuildLocalSlots(
        SmartPushEnabledUserDto user,
        DateOnly day,
        int slotsPerDay,
        TimeSpan windowStart,
        TimeSpan windowEnd)
    {
        var primary = MidpointOfPeak(user.PeakEnergyTimeWindow)
            ?? user.PreferredReminderTime
            ?? new TimeSpan(8, 0, 0);
        primary = Clamp(primary, windowStart, windowEnd);

        if (slotsPerDay == 1)
            return [day.ToDateTime(TimeOnly.FromTimeSpan(primary))];

        var slotA = primary;
        var slotB = new TimeSpan(18, 30, 0);
        if (slotB < windowStart || slotB > windowEnd)
            slotB = windowEnd.Subtract(TimeSpan.FromMinutes(30));
        if (slotB - slotA < TimeSpan.FromHours(5))
            slotB = Clamp(slotA.Add(TimeSpan.FromHours(5)), windowStart, windowEnd);

        return
        [
            day.ToDateTime(TimeOnly.FromTimeSpan(slotA)),
            day.ToDateTime(TimeOnly.FromTimeSpan(slotB))
        ];
    }

    private static TimeSpan? MidpointOfPeak(string? peak)
    {
        if (string.IsNullOrWhiteSpace(peak)) return null;
        var parts = peak.Split('-', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length != 2) return null;
        if (!TimeSpan.TryParse(parts[0], out var a) || !TimeSpan.TryParse(parts[1], out var b))
            return null;
        return TimeSpan.FromTicks((a.Ticks + b.Ticks) / 2);
    }

    private static TimeSpan Clamp(TimeSpan value, TimeSpan min, TimeSpan max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private static TimeSpan ParseTime(string raw, TimeSpan fallback) =>
        TimeSpan.TryParse(raw, out var t) ? t : fallback;

    private static TimeZoneInfo ResolveTz(string? tzId)
    {
        var id = string.IsNullOrWhiteSpace(tzId) ? "Asia/Ho_Chi_Minh" : tzId;
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById(id);
        }
        catch
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
        }
    }

    private static DateTimeOffset ToUtc(DateTime localUnspecified, TimeZoneInfo tz)
    {
        var unspecified = DateTime.SpecifyKind(localUnspecified, DateTimeKind.Unspecified);
        return new DateTimeOffset(unspecified, tz.GetUtcOffset(unspecified)).ToUniversalTime();
    }

    private static DateTimeOffset ClampToWindowUtc(
        DateTimeOffset utc,
        TimeZoneInfo tz,
        TimeSpan windowStart,
        TimeSpan windowEnd)
    {
        var local = TimeZoneInfo.ConvertTime(utc, tz);
        var tod = local.TimeOfDay;
        if (tod < windowStart)
            return ToUtc(DateOnly.FromDateTime(local.DateTime).ToDateTime(TimeOnly.FromTimeSpan(windowStart)), tz);
        if (tod > windowEnd)
            return ToUtc(DateOnly.FromDateTime(local.DateTime).AddDays(1).ToDateTime(TimeOnly.FromTimeSpan(windowStart)), tz);
        return utc;
    }
}
