namespace Iam.Application.DTOs;

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

public class IamDashboardOverviewDto
{
    public DateTimeOffset GeneratedAt { get; set; }
    public int Days { get; set; }
    public KpiMetricDto Dau { get; set; } = new();
    public KpiMetricDto Wau { get; set; } = new();
    public KpiMetricDto Mau { get; set; } = new();
    public KpiMetricDto NewUsers { get; set; } = new();
    public KpiMetricDto PremiumUsers { get; set; } = new();
    public KpiMetricDto ChurnRate { get; set; } = new();
    public IReadOnlyList<DailyPointDto> UserGrowthDaily { get; set; } = [];
    public IReadOnlyList<DailyPointDto> UserGrowthCumulative { get; set; } = [];
    public IReadOnlyList<DailyPointDto> ActiveUsersDaily { get; set; } = [];
    public IReadOnlyList<NamedCountDto> TierDistribution { get; set; } = [];
    public IReadOnlyList<NamedCountDto> PlatformDistribution { get; set; } = [];
    public IReadOnlyList<AdminUserListItemDto> RecentUsers { get; set; } = [];
}
