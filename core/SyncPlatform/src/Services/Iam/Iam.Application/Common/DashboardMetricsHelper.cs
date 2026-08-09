using Iam.Application.DTOs;

namespace Iam.Application.Common;

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

    public static IReadOnlyList<DailyPointDto> FillDailySeries(
        DateOnly start,
        DateOnly end,
        IReadOnlyDictionary<DateOnly, decimal> counts)
    {
        var result = new List<DailyPointDto>();
        for (var d = start; d <= end; d = d.AddDays(1))
        {
            counts.TryGetValue(d, out var value);
            result.Add(new DailyPointDto { Date = d.ToString("yyyy-MM-dd"), Value = value });
        }
        return result;
    }
}
