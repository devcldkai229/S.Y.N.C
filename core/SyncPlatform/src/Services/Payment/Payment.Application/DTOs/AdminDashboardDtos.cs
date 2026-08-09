namespace Payment.Application.DTOs;

public class DashboardQueryDto
{
    public int Days { get; set; } = 30;
}

public class DailyPointDto
{
    public string Date { get; set; } = string.Empty;
    public decimal Value { get; set; }
}

public class StackedDailyPointDto
{
    public string Date { get; set; } = string.Empty;
    public decimal Subscription { get; set; }
    public decimal Other { get; set; }
}

public class KpiMetricDto
{
    public decimal Value { get; set; }
    public decimal? PreviousValue { get; set; }
    public decimal? DeltaPercent { get; set; }
    public IReadOnlyList<DailyPointDto> Sparkline { get; set; } = [];
}

public class NamedCountDto
{
    public string Name { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class PaymentDashboardOverviewDto
{
    public DateTimeOffset GeneratedAt { get; set; }
    public int Days { get; set; }
    public KpiMetricDto SubscriptionRevenue { get; set; } = new();
    public KpiMetricDto ActiveSubscriptions { get; set; } = new();
    public KpiMetricDto NewSubscriptions { get; set; } = new();
    public KpiMetricDto CancelledSubscriptions { get; set; } = new();
    public IReadOnlyList<StackedDailyPointDto> RevenueDaily { get; set; } = [];
    public IReadOnlyList<NamedCountDto> PaymentMethodDistribution { get; set; } = [];
    public IReadOnlyList<NamedCountDto> PromotionUsage { get; set; } = [];
}
