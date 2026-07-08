using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Payment.Application.Clients;
using Payment.Domain.Enums;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Jobs;

/// <summary>
/// Runs every 6 hours. Re-syncs IAM tier=Premium for users with an active paid subscription
/// when webhook/expiry sync may have drifted.
/// </summary>
public class SubscriptionTierReconcileJob : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SubscriptionTierReconcileJob> _logger;

    public SubscriptionTierReconcileJob(
        IServiceScopeFactory scopeFactory,
        ILogger<SubscriptionTierReconcileJob> logger)
    {
        _scopeFactory = scopeFactory;
        _logger       = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("SubscriptionTierReconcileJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "SubscriptionTierReconcileJob encountered an error.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    private async Task RunAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db        = scope.ServiceProvider.GetRequiredService<PaymentDbContext>();
        var iamClient = scope.ServiceProvider.GetRequiredService<IIamSubscriptionClient>();

        var now = DateTimeOffset.UtcNow;

        var activeUserIds = await db.UserSubscriptions
            .AsNoTracking()
            .Where(s =>
                s.Status == SubscriptionStatus.Active &&
                (s.ExpiredAt == null || s.ExpiredAt > now))
            .Select(s => s.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        if (activeUserIds.Count == 0) return;

        var synced = 0;
        foreach (var userId in activeUserIds)
        {
            try
            {
                await iamClient.SetTierAsync(userId, "Premium", cancellationToken);
                synced++;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex,
                    "SubscriptionTierReconcileJob: failed to sync Premium for UserId={UserId}.",
                    userId);
            }
        }

        _logger.LogInformation(
            "SubscriptionTierReconcileJob: reconciled Premium tier for {Synced}/{Total} active subscribers.",
            synced,
            activeUserIds.Count);
    }
}
