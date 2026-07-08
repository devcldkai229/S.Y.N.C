using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Notification.Application.Services.SmartPush;

namespace Notification.API.BackgroundWorkers;

public class SmartPushPlannerWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmartPushPlannerWorker> _logger;

    public SmartPushPlannerWorker(
        IServiceProvider serviceProvider,
        IConfiguration configuration,
        ILogger<SmartPushPlannerWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var enabled = _configuration.GetValue<bool>("SmartPush:Enabled", true);
        if (!enabled)
        {
            _logger.LogWarning("Smart Push Planner Worker is disabled in configuration.");
            return;
        }

        // Run every 30 minutes (1800 seconds)
        var intervalSeconds = _configuration.GetValue<int>("SmartPush:PlannerIntervalSeconds", 1800);
        _logger.LogInformation("Smart Push Planner Worker started with interval of {Interval} seconds.", intervalSeconds);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Smart Push Planner cycle started.");

                using (var scope = _serviceProvider.CreateScope())
                {
                    var smartPushService = scope.ServiceProvider.GetRequiredService<ISmartPushNotificationService>();
                    await smartPushService.ProcessDueUsersAsync(DateTime.UtcNow, cancellationToken: stoppingToken);
                }

                _logger.LogInformation("Smart Push Planner cycle completed.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An unhandled exception occurred in Smart Push Planner Worker cycle.");
            }

            try
            {
                await Task.Delay(TimeSpan.FromSeconds(intervalSeconds), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }

        _logger.LogInformation("Smart Push Planner Worker stopped.");
    }
}
