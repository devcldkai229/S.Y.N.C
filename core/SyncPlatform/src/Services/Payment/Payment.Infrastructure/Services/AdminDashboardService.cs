using Microsoft.EntityFrameworkCore;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public sealed class AdminDashboardService : IAdminDashboardService
{
    private readonly PaymentDbContext _db;

    public AdminDashboardService(PaymentDbContext db) => _db = db;

    public async Task<PaymentDashboardOverviewDto> GetOverviewAsync(
        DashboardQueryDto query,
        CancellationToken cancellationToken = default)
    {
        var days = Math.Clamp(query.Days, 1, 365);
        var now = DateTimeOffset.UtcNow;
        var periodStart = now.AddDays(-days);
        var previousStart = now.AddDays(-days * 2);
        var chartStart = DashboardMetricsHelper.ToVnDate(now.AddDays(-days));
        var chartEnd = DashboardMetricsHelper.ToVnDate(now);

        var succeeded = await _db.Transactions
            .AsNoTracking()
            .Where(t => t.Status == TransactionStatus.Succeeded && t.ProcessedAt != null)
            .ToListAsync(cancellationToken);

        var subs = await _db.UserSubscriptions.AsNoTracking().ToListAsync(cancellationToken);
        var promotions = await _db.PromotionCampaigns.AsNoTracking().ToListAsync(cancellationToken);

        decimal SubRevenue(DateTimeOffset from, DateTimeOffset to) =>
            succeeded
                .Where(t => t.TransactionType == TransactionType.Subscription
                    && t.ProcessedAt >= from && t.ProcessedAt < to)
                .Sum(t => t.Amount);

        var subRevCurrent = SubRevenue(periodStart, now);
        var subRevPrevious = SubRevenue(previousStart, periodStart);

        var activeNow = subs.Count(s =>
            (s.Status == SubscriptionStatus.Active || s.Status == SubscriptionStatus.Cancelled)
            && s.ExpiredAt > now);
        var activePrev = subs.Count(s =>
            (s.Status == SubscriptionStatus.Active || s.Status == SubscriptionStatus.Cancelled)
            && s.ExpiredAt > previousStart && s.StartedAt < periodStart);

        var newSubs = subs.Count(s => s.StartedAt >= periodStart && s.StartedAt < now);
        var newSubsPrev = subs.Count(s => s.StartedAt >= previousStart && s.StartedAt < periodStart);

        var cancelled = subs.Count(s =>
            s.Status == SubscriptionStatus.Cancelled
            && s.UpdatedAt >= periodStart && s.UpdatedAt < now);
        var cancelledPrev = subs.Count(s =>
            s.Status == SubscriptionStatus.Cancelled
            && s.UpdatedAt >= previousStart && s.UpdatedAt < periodStart);

        var revenueDaily = new List<StackedDailyPointDto>();
        var subSpark = new List<DailyPointDto>();
        for (var d = chartStart; d <= chartEnd; d = d.AddDays(1))
        {
            var dayStart = new DateTimeOffset(d.ToDateTime(TimeOnly.MinValue), TimeSpan.FromHours(7)).ToUniversalTime();
            var dayEnd = dayStart.AddDays(1);
            var dayTx = succeeded.Where(t => t.ProcessedAt >= dayStart && t.ProcessedAt < dayEnd).ToList();
            var sub = dayTx.Where(t => t.TransactionType == TransactionType.Subscription).Sum(t => t.Amount);
            var other = dayTx.Where(t => t.TransactionType != TransactionType.Subscription).Sum(t => t.Amount);
            revenueDaily.Add(new StackedDailyPointDto
            {
                Date = d.ToString("yyyy-MM-dd"),
                Subscription = sub,
                Other = other,
            });
            subSpark.Add(new DailyPointDto { Date = d.ToString("yyyy-MM-dd"), Value = sub + other });
        }

        var paymentMethods = succeeded
            .Where(t => t.ProcessedAt >= periodStart)
            .GroupBy(t => t.PaymentMethod)
            .Select(g => new NamedCountDto { Name = g.Key.ToString(), Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .ToList();

        var promoUsage = promotions
            .Where(p => p.UsageCount > 0)
            .OrderByDescending(p => p.UsageCount)
            .Take(10)
            .Select(p => new NamedCountDto { Name = p.Name, Count = p.UsageCount })
            .ToList();

        return new PaymentDashboardOverviewDto
        {
            GeneratedAt = now,
            Days = days,
            SubscriptionRevenue = DashboardMetricsHelper.BuildKpi(
                subRevCurrent, subRevPrevious, DashboardMetricsHelper.BuildSparkline(subSpark)),
            ActiveSubscriptions = DashboardMetricsHelper.BuildKpi(activeNow, activePrev),
            NewSubscriptions = DashboardMetricsHelper.BuildKpi(newSubs, newSubsPrev),
            CancelledSubscriptions = DashboardMetricsHelper.BuildKpi(cancelled, cancelledPrev),
            RevenueDaily = revenueDaily,
            PaymentMethodDistribution = paymentMethods,
            PromotionUsage = promoUsage,
        };
    }
}
