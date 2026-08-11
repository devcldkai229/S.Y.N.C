namespace Libs.Shared.Time;

/// <summary>Resolve user-local calendar day boundaries (DB stays UTC; compare in user TZ).</summary>
public static class UserLocalTime
{
    public const string DefaultTimeZoneId = "Asia/Ho_Chi_Minh";

    /// <summary>Windows legacy ID for Vietnam (UTC+7, no DST).</summary>
    public const string WindowsVietnamTimeZoneId = "SE Asia Standard Time";

    /// <summary>
    /// Guaranteed offset for Vietnam product default when IANA zoneinfo is missing
    /// (e.g. .NET noble-chiseled images without /usr/share/zoneinfo).
    /// </summary>
    public static readonly TimeSpan VietnamFixedOffset = TimeSpan.FromHours(7);

    public static TimeZoneInfo ResolveTimeZone(string? timeZoneId)
    {
        var tzId = string.IsNullOrWhiteSpace(timeZoneId) ? DefaultTimeZoneId : timeZoneId.Trim();
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById(tzId);
        }
        catch (Exception)
        {
            // Windows hosts often only know the legacy ID for Vietnam (UTC+7).
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(WindowsVietnamTimeZoneId);
            }
            catch (Exception)
            {
                // Chiseled Linux images lack zoneinfo; do not re-Find Asia/Ho_Chi_Minh.
                return TimeZoneInfo.CreateCustomTimeZone(
                    "UTC+07",
                    VietnamFixedOffset,
                    "UTC+07",
                    "UTC+07");
            }
        }
    }

    /// <summary>Start of today (local) as DateTimeOffset; exclusive end = +1 day.</summary>
    public static (DateTimeOffset Start, DateTimeOffset EndExclusive) TodayRange(string? timeZoneId)
    {
        var tz = ResolveTimeZone(timeZoneId);
        var localNow = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, tz);
        var localStart = new DateTime(localNow.Year, localNow.Month, localNow.Day, 0, 0, 0, DateTimeKind.Unspecified);
        var start = new DateTimeOffset(localStart, tz.GetUtcOffset(localStart));
        return (start, start.AddDays(1));
    }

    public static DateOnly TodayDate(string? timeZoneId)
    {
        var (start, _) = TodayRange(timeZoneId);
        return DateOnly.FromDateTime(start.DateTime);
    }

    /// <summary>Inclusive local calendar day as UTC half-open range [start, end).</summary>
    public static (DateTimeOffset Start, DateTimeOffset EndExclusive) DayRange(
        DateOnly date,
        string? timeZoneId)
    {
        var tz = ResolveTimeZone(timeZoneId);
        var localStart = date.ToDateTime(TimeOnly.MinValue);
        var start = new DateTimeOffset(localStart, tz.GetUtcOffset(localStart));
        return (start, start.AddDays(1));
    }

    /// <summary>Calendar date of an instant in the user's timezone.</summary>
    public static DateOnly ToLocalDate(DateTimeOffset instant, string? timeZoneId)
    {
        var tz = ResolveTimeZone(timeZoneId);
        var local = TimeZoneInfo.ConvertTime(instant, tz);
        return DateOnly.FromDateTime(local.DateTime);
    }

    /// <summary>Noon local on [date] — stable default for diary entries without clock time.</summary>
    public static DateTimeOffset NoonOnDate(DateOnly date, string? timeZoneId)
    {
        var (start, _) = DayRange(date, timeZoneId);
        return start.AddHours(12);
    }

    /// <summary>Default [end-days .. end] window ending at local now (inclusive end ≈ now).</summary>
    public static (DateTimeOffset Start, DateTimeOffset End) LastDaysRange(string? timeZoneId, int days = 7)
    {
        var tz = ResolveTimeZone(timeZoneId);
        var end = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, tz);
        var start = end.AddDays(-Math.Max(1, days));
        return (start, end);
    }
}
