using Microsoft.Extensions.Options;
using Notification.Application.Options;
using Notification.Application.Services.SmartPush;

namespace Notification.API.BackgroundWorkers;

public class SmartPushNightlyRecomputeWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly SmartPushOptions _options;
    private readonly ILogger<SmartPushNightlyRecomputeWorker> _logger;

    public SmartPushNightlyRecomputeWorker(
        IServiceProvider serviceProvider,
        IOptions<SmartPushOptions> options,
        ILogger<SmartPushNightlyRecomputeWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _options = options.Value;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_options.Enabled)
        {
            _logger.LogWarning("Smart Push nightly recompute is disabled (SmartPush:Enabled=false).");
            return;
        }

        _logger.LogInformation("Smart Push nightly recompute worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var delay = ComputeDelayUntilNextRun(DateTimeOffset.UtcNow);
                _logger.LogInformation("Next smart push nightly recompute in {Delay}.", delay);
                await Task.Delay(delay, stoppingToken);

                using var scope = _serviceProvider.CreateScope();
                var svc = scope.ServiceProvider.GetRequiredService<ISmartPushNotificationService>();
                await svc.NightlyRecomputeAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Smart Push nightly recompute failed.");
                try { await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); }
                catch (OperationCanceledException) { break; }
            }
        }
    }

    private TimeSpan ComputeDelayUntilNextRun(DateTimeOffset utcNow)
    {
        // Run at ~00:15 Asia/Ho_Chi_Minh by default (local wall for VN platform ops).
        TimeZoneInfo tz;
        try { tz = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh"); }
        catch { tz = TimeZoneInfo.Utc; }

        var local = TimeZoneInfo.ConvertTime(utcNow, tz);
        var targetTod = _options.NightlyRecomputeAtLocal;
        var nextLocalDate = DateOnly.FromDateTime(local.DateTime);
        var nextLocal = nextLocalDate.ToDateTime(TimeOnly.FromTimeSpan(targetTod));
        if (local.TimeOfDay >= targetTod)
            nextLocal = nextLocal.AddDays(1);

        var unspecified = DateTime.SpecifyKind(nextLocal, DateTimeKind.Unspecified);
        var nextUtc = new DateTimeOffset(unspecified, tz.GetUtcOffset(unspecified)).ToUniversalTime();
        var delay = nextUtc - utcNow;
        return delay < TimeSpan.FromMinutes(1) ? TimeSpan.FromMinutes(1) : delay;
    }
}
