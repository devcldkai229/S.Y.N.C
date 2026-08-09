namespace Payment.Application.Common;

using Payment.Application.DTOs;

public static class DashboardMetricsHelper
{
    private static readonly TimeSpan VnOffset = TimeSpan.FromHours(7);

    public static DateOnly ToVnDate(DateTimeOffset utc) =>
        DateOnly.FromDateTime(utc.UtcDateTime.Add(VnOffset));

    public static decimal? ComputeDeltaPercent(decimal current, decimal previous)
    {
        if (previous == 0)
            return current > 0 ? 100 : 0;
        return Math.Round((current - previous) / previous * 100m, 1);
    }

    public static KpiMetricDto BuildKpi(
        decimal current,
        decimal previous,
        IReadOnlyList<DailyPointDto>? sparkline = null) => new()
    {
        Value = current,
        PreviousValue = previous,
        DeltaPercent = ComputeDeltaPercent(current, previous),
        Sparkline = sparkline ?? [],
    };

    public static IReadOnlyList<DailyPointDto> BuildSparkline(
        IEnumerable<DailyPointDto> daily,
        int days = 14) =>
        daily.OrderBy(d => d.Date, StringComparer.Ordinal).TakeLast(days).ToList();
}
