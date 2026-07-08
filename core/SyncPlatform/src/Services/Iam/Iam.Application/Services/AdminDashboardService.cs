using Iam.Application.Abstractions;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Domain.Enums;
using Libs.Storage.Services;

namespace Iam.Application.Services;

public sealed class AdminDashboardService : IAdminDashboardService
{
    private readonly IAdminDashboardReadRepository _repo;
    private readonly IMediaUrlResolver _media;

    public AdminDashboardService(IAdminDashboardReadRepository repo, IMediaUrlResolver media)
    {
        _repo = repo;
        _media = media;
    }

    public async Task<IamDashboardOverviewDto> GetOverviewAsync(
        DashboardQueryDto query,
        CancellationToken cancellationToken = default)
    {
        var days = Math.Clamp(query.Days, 1, 365);
        var now = DateTimeOffset.UtcNow;
        var periodStart = now.AddDays(-days);
        var previousStart = now.AddDays(-days * 2);
        var chartStart = DashboardMetricsHelper.ToVnDate(now.AddDays(-days));
        var chartEnd = DashboardMetricsHelper.ToVnDate(now);

        var users = await _repo.GetUserRowsAsync(cancellationToken);
        var platforms = await _repo.GetPlatformCountsAsync(cancellationToken);

        var dau = CountActiveSince(users, now.AddDays(-1));
        var prevDau = CountActiveInWindow(users, now.AddDays(-2), now.AddDays(-1));
        var wau = CountActiveSince(users, now.AddDays(-7));
        var prevWau = CountActiveInWindow(users, now.AddDays(-14), now.AddDays(-7));
        var mau = CountActiveSince(users, now.AddDays(-30));
        var prevMau = CountActiveInWindow(users, now.AddDays(-60), now.AddDays(-30));

        var newUsersCurrent = users.Count(u => u.CreatedAt >= periodStart);
        var newUsersPrevious = users.Count(u => u.CreatedAt >= previousStart && u.CreatedAt < periodStart);

        var premiumCurrent = users.Count(u =>
            u.SubscriptionTier == SubscriptionTier.Premium && u.Status == UserStatus.Active);
        var premiumPrevious = premiumCurrent; // snapshot — delta minimal for tier count

        var churnCurrent = ComputeChurnRate(users, periodStart, now);
        var churnPrevious = ComputeChurnRate(users, previousStart, periodStart);

        var growthDailyMap = users
            .Where(u => DashboardMetricsHelper.ToVnDate(u.CreatedAt) >= chartStart)
            .GroupBy(u => DashboardMetricsHelper.ToVnDate(u.CreatedAt))
            .ToDictionary(g => g.Key, g => (decimal)g.Count());

        var growthDaily = DashboardMetricsHelper.FillDailySeries(chartStart, chartEnd, growthDailyMap);
        var cumulative = 0m;
        var growthCumulative = growthDaily.Select(p =>
        {
            cumulative += p.Value;
            return new DailyPointDto { Date = p.Date, Value = cumulative };
        }).ToList();

        var activeDailyMap = new Dictionary<DateOnly, decimal>();
        for (var d = chartStart; d <= chartEnd; d = d.AddDays(1))
        {
            var dayStart = new DateTimeOffset(d.ToDateTime(TimeOnly.MinValue), TimeSpan.FromHours(7)).ToUniversalTime();
            var dayEnd = dayStart.AddDays(1);
            activeDailyMap[d] = users.Count(u =>
                u.LastActiveAt.HasValue && u.LastActiveAt >= dayStart && u.LastActiveAt < dayEnd);
        }
        var activeDaily = DashboardMetricsHelper.FillDailySeries(chartStart, chartEnd, activeDailyMap);

        var tierDistribution = users
            .GroupBy(u => u.SubscriptionTier)
            .Select(g => new NamedCountDto { Name = g.Key.ToString(), Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .ToList();

        var platformDistribution = platforms
            .Select(p => new NamedCountDto { Name = p.Platform, Count = p.Count })
            .OrderByDescending(x => x.Count)
            .ToList();

        var recentUsers = users
            .OrderByDescending(u => u.CreatedAt)
            .Take(5)
            .Select(MapUser)
            .ToList();

        var newUsersSpark = DashboardMetricsHelper.BuildSparkline(growthDaily);

        return new IamDashboardOverviewDto
        {
            GeneratedAt = now,
            Days = days,
            Dau = DashboardMetricsHelper.BuildKpi(dau, prevDau),
            Wau = DashboardMetricsHelper.BuildKpi(wau, prevWau),
            Mau = DashboardMetricsHelper.BuildKpi(mau, prevMau),
            NewUsers = DashboardMetricsHelper.BuildKpi(newUsersCurrent, newUsersPrevious, newUsersSpark),
            PremiumUsers = DashboardMetricsHelper.BuildKpi(premiumCurrent, premiumPrevious),
            ChurnRate = DashboardMetricsHelper.BuildKpi(churnCurrent, churnPrevious),
            UserGrowthDaily = growthDaily,
            UserGrowthCumulative = growthCumulative,
            ActiveUsersDaily = activeDaily,
            TierDistribution = tierDistribution,
            PlatformDistribution = platformDistribution,
            RecentUsers = recentUsers,
        };
    }

    private static int CountActiveSince(IReadOnlyList<UserDashboardRow> users, DateTimeOffset since) =>
        users.Count(u => u.LastActiveAt.HasValue && u.LastActiveAt >= since);

    private static int CountActiveInWindow(
        IReadOnlyList<UserDashboardRow> users,
        DateTimeOffset start,
        DateTimeOffset end) =>
        users.Count(u => u.LastActiveAt.HasValue && u.LastActiveAt >= start && u.LastActiveAt < end);

    private static decimal ComputeChurnRate(
        IReadOnlyList<UserDashboardRow> users,
        DateTimeOffset periodStart,
        DateTimeOffset periodEnd)
    {
        var cohort = users.Where(u => u.CreatedAt < periodStart).ToList();
        if (cohort.Count == 0)
            return 0;

        var wasActiveBefore = cohort.Count(u =>
            u.LastActiveAt.HasValue &&
            u.LastActiveAt >= periodStart.AddDays(-30) &&
            u.LastActiveAt < periodStart);
        if (wasActiveBefore == 0)
            return 0;

        var churned = cohort.Count(u =>
        {
            var activePrior = u.LastActiveAt.HasValue &&
                u.LastActiveAt >= periodStart.AddDays(-30) &&
                u.LastActiveAt < periodStart;
            var activeInPeriod = u.LastActiveAt.HasValue &&
                u.LastActiveAt >= periodStart &&
                u.LastActiveAt < periodEnd;
            return activePrior && !activeInPeriod;
        });

        return Math.Round((decimal)churned / wasActiveBefore * 100m, 1);
    }

    private AdminUserListItemDto MapUser(UserDashboardRow u) => new()
    {
        Id = u.Id,
        Email = u.Email,
        FullName = u.FullName,
        AvatarUrl = _media.ResolveForDisplay(u.AvatarUrl),
        Role = u.Role,
        Status = u.Status,
        SubscriptionTier = u.SubscriptionTier,
        EmailVerified = u.EmailVerified,
        LastActiveAt = u.LastActiveAt,
        LastLoginAt = u.LastLoginAt,
        CreatedAt = u.CreatedAt,
    };
}
