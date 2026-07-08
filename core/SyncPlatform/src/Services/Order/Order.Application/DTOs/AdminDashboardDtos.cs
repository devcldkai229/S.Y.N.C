namespace Order.Application.DTOs;

public class DashboardQueryDto
{
    public int Days { get; set; } = 30;
}

public class DailyPointDto
{
    public string Date { get; set; } = string.Empty;
    public decimal Value { get; set; }
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

public class NamedAmountDto
{
    public string Name { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class OrderDashboardOverviewDto
{
    public DateTimeOffset GeneratedAt { get; set; }
    public int Days { get; set; }
    public KpiMetricDto Gmv { get; set; } = new();
    public KpiMetricDto OrderCount { get; set; } = new();
    public KpiMetricDto CommissionRevenue { get; set; } = new();
    public IReadOnlyList<DailyPointDto> OrdersDaily { get; set; } = [];
    public IReadOnlyList<DailyPointDto> GmvDaily { get; set; } = [];
    public IReadOnlyList<NamedCountDto> OrderStatusDistribution { get; set; } = [];
    public IReadOnlyList<NamedAmountDto> TopPartners { get; set; } = [];
}
