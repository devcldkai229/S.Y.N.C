using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Payment.Application.Clients;
using Payment.Domain.Enums;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Jobs;

/// <summary>
/// Runs every hour. Finds UserSubscriptions whose ExpiredAt has passed (Active or Cancelled)
/// and marks them Expired, then syncs tier=Free to IAM if the user has no other live subscription.
/// </summary>
public class SubscriptionExpiryJob : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SubscriptionExpiryJob> _logger;

    public SubscriptionExpiryJob(IServiceScopeFactory scopeFactory, ILogger<SubscriptionExpiryJob> logger)
    {
        _scopeFactory = scopeFactory;
        _logger       = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("SubscriptionExpiryJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "SubscriptionExpiryJob encountered an error.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    private async Task RunAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db         = scope.ServiceProvider.GetRequiredService<PaymentDbContext>();
        var iamClient  = scope.ServiceProvider.GetRequiredService<IIamSubscriptionClient>();

        var now = DateTimeOffset.UtcNow;

        // Tìm tất cả sub hết hạn (Active hoặc Cancelled còn trong validity period đã qua)
        var expired = await db.UserSubscriptions
            .Where(s =>
                s.ExpiredAt != null &&
                s.ExpiredAt < now &&
                (s.Status == SubscriptionStatus.Active || s.Status == SubscriptionStatus.Cancelled))
            .ToListAsync(cancellationToken);

        if (expired.Count == 0) return;

        _logger.LogInformation("SubscriptionExpiryJob: {Count} subscriptions to expire.", expired.Count);

        // Group theo UserId để xử lý từng user 1 lần
        var byUser = expired.GroupBy(s => s.UserId);

        foreach (var group in byUser)
        {
            var userId = group.Key;

            foreach (var sub in group)
            {
                sub.Status    = SubscriptionStatus.Expired;
                sub.UpdatedAt = now;
            }

            // Kiểm tra xem user còn gói active nào khác không
            var hasOtherActive = await db.UserSubscriptions
                .AnyAsync(s =>
                    s.UserId == userId &&
                    s.Status == SubscriptionStatus.Active &&
                    (s.ExpiredAt == null || s.ExpiredAt > now) &&
                    !expired.Select(e => e.Id).Contains(s.Id),
                    cancellationToken);

            if (!hasOtherActive)
            {
                await SyncTierSafeAsync(iamClient, userId, "Free", cancellationToken);
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("SubscriptionExpiryJob: expired {Count} subscriptions.", expired.Count);
    }

    private async Task SyncTierSafeAsync(IIamSubscriptionClient client, Guid userId, string tier, CancellationToken ct)
    {
        try
        {
            await client.SetTierAsync(userId, tier, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex,
                "SubscriptionExpiryJob: failed to sync tier={Tier} to IAM for UserId={UserId}.",
                tier, userId);
        }
    }
}
