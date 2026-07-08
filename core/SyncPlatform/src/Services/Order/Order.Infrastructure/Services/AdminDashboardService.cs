using Microsoft.EntityFrameworkCore;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public sealed class AdminDashboardService : IAdminDashboardService
{
    private readonly OrderDbContext _db;

    public AdminDashboardService(OrderDbContext db) => _db = db;

    public async Task<OrderDashboardOverviewDto> GetOverviewAsync(
        DashboardQueryDto query,
        CancellationToken cancellationToken = default)
    {
        var days = Math.Clamp(query.Days, 1, 365);
        var now = DateTimeOffset.UtcNow;
        var periodStart = now.AddDays(-days);
        var previousStart = now.AddDays(-days * 2);
        var chartStart = DashboardMetricsHelper.ToVnDate(now.AddDays(-days));
        var chartEnd = DashboardMetricsHelper.ToVnDate(now);

        var orders = await _db.Orders.AsNoTracking().ToListAsync(cancellationToken);
        var commissions = await _db.CommissionRecords.AsNoTracking().ToListAsync(cancellationToken);

        decimal Gmv(DateTimeOffset from, DateTimeOffset to) =>
            orders.Where(o => o.PlacedAt >= from && o.PlacedAt < to).Sum(o => o.TotalAmount);

        int OrderCnt(DateTimeOffset from, DateTimeOffset to) =>
            orders.Count(o => o.PlacedAt >= from && o.PlacedAt < to);

        decimal Commission(DateTimeOffset from, DateTimeOffset to) =>
            commissions.Where(c => c.CreatedAt >= from && c.CreatedAt < to).Sum(c => c.CommissionAmount);

        var gmvCurrent = Gmv(periodStart, now);
        var gmvPrevious = Gmv(previousStart, periodStart);
        var ordersCurrent = OrderCnt(periodStart, now);
        var ordersPrevious = OrderCnt(previousStart, periodStart);
        var commCurrent = Commission(periodStart, now);
        var commPrevious = Commission(previousStart, periodStart);

        var ordersDaily = new List<DailyPointDto>();
        var gmvDaily = new List<DailyPointDto>();
        for (var d = chartStart; d <= chartEnd; d = d.AddDays(1))
        {
            var dayStart = new DateTimeOffset(d.ToDateTime(TimeOnly.MinValue), TimeSpan.FromHours(7)).ToUniversalTime();
            var dayEnd = dayStart.AddDays(1);
            var dayOrders = orders.Where(o => o.PlacedAt >= dayStart && o.PlacedAt < dayEnd).ToList();
            ordersDaily.Add(new DailyPointDto
            {
                Date = d.ToString("yyyy-MM-dd"),
                Value = dayOrders.Count,
            });
            gmvDaily.Add(new DailyPointDto
            {
                Date = d.ToString("yyyy-MM-dd"),
                Value = dayOrders.Sum(o => o.TotalAmount),
            });
        }

        var statusDist = orders
            .Where(o => o.PlacedAt >= periodStart)
            .GroupBy(o => o.Status)
            .Select(g => new NamedCountDto { Name = g.Key.ToString(), Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .ToList();

        var topPartners = orders
            .Where(o => o.PlacedAt >= periodStart)
            .GroupBy(o => o.PartnerId)
            .Select(g => new NamedAmountDto
            {
                Name = g.Key.ToString()[..8] + "…",
                Amount = g.Sum(o => o.TotalAmount),
            })
            .OrderByDescending(x => x.Amount)
            .Take(10)
            .ToList();

        return new OrderDashboardOverviewDto
        {
            GeneratedAt = now,
            Days = days,
            Gmv = DashboardMetricsHelper.BuildKpi(gmvCurrent, gmvPrevious, DashboardMetricsHelper.BuildSparkline(gmvDaily)),
            OrderCount = DashboardMetricsHelper.BuildKpi(ordersCurrent, ordersPrevious, DashboardMetricsHelper.BuildSparkline(ordersDaily)),
            CommissionRevenue = DashboardMetricsHelper.BuildKpi(commCurrent, commPrevious),
            OrdersDaily = ordersDaily,
            GmvDaily = gmvDaily,
            OrderStatusDistribution = statusDist,
            TopPartners = topPartners,
        };
    }
}
