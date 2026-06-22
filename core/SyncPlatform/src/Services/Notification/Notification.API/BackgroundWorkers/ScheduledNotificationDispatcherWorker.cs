using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Notification.Application.Services;

namespace Notification.API.BackgroundWorkers;

public class ScheduledNotificationDispatcherWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ScheduledNotificationDispatcherWorker> _logger;

    public ScheduledNotificationDispatcherWorker(
        IServiceProvider serviceProvider,
        IConfiguration configuration,
        ILogger<ScheduledNotificationDispatcherWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Run every 60 seconds (1 minute)
        var intervalSeconds = _configuration.GetValue<int>("SmartPush:DispatcherIntervalSeconds", 60);
        _logger.LogInformation("Scheduled Notification Dispatcher Worker started with interval of {Interval} seconds.", intervalSeconds);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogDebug("Scheduled Notification Dispatcher cycle started.");

                using (var scope = _serviceProvider.CreateScope())
                {
                    var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                    await notificationService.ProcessScheduledNotificationsAsync(stoppingToken);
                }

                _logger.LogDebug("Scheduled Notification Dispatcher cycle completed.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An unhandled exception occurred in Scheduled Notification Dispatcher Worker cycle.");
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

        _logger.LogInformation("Scheduled Notification Dispatcher Worker stopped.");
    }
}
