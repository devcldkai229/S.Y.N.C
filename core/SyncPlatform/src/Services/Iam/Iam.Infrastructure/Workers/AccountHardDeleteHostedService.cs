using Iam.Domain.Enums;
using Iam.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Iam.Infrastructure.Workers;

/// <summary>
/// Minimal grace-period job: finds soft-deleted users past <see cref="Iam.Domain.Models.User.ScheduledHardDeleteAt"/>
/// and clears the schedule marker (PII already anonymized at soft-delete time).
/// </summary>
public sealed class AccountHardDeleteHostedService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<AccountHardDeleteHostedService> _logger;

    public AccountHardDeleteHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<AccountHardDeleteHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AccountHardDeleteHostedService started.");

        // Let the API finish startup before first pass.
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessDueAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "AccountHardDeleteHostedService encountered an error.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    private async Task ProcessDueAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IamDbContext>();
        var now = DateTimeOffset.UtcNow;

        // Soft-deleted users are hidden by the global query filter.
        var due = await db.Users
            .IgnoreQueryFilters()
            .Where(u =>
                u.Status == UserStatus.Deleted
                && u.ScheduledHardDeleteAt != null
                && u.ScheduledHardDeleteAt <= now)
            .Take(100)
            .ToListAsync(cancellationToken);

        if (due.Count == 0)
            return;

        foreach (var user in due)
        {
            // PII was already anonymized at soft-delete; ensure scrub is idempotent.
            if (string.IsNullOrWhiteSpace(user.FullName) || user.FullName == "Deleted User")
                user.FullName = "Deleted User";

            if (string.IsNullOrWhiteSpace(user.Email) || !user.Email.Contains("@deleted.sync.local", StringComparison.OrdinalIgnoreCase))
                user.Email = $"deleted+{user.Id:N}@deleted.sync.local";

            user.ScheduledHardDeleteAt = null;
            user.UpdatedAt = now;
        }

        await db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation(
            "AccountHardDeleteHostedService: processed {Count} accounts past grace period.",
            due.Count);
    }
}
