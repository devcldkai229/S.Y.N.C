using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Notification.Application.Services.SmartPush;

namespace Notification.API.BackgroundWorkers;

public class SmartPushNotificationWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmartPushNotificationWorker> _logger;

    public SmartPushNotificationWorker(
        IServiceProvider serviceProvider,
        IConfiguration configuration,
        ILogger<SmartPushNotificationWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var enabled = _configuration.GetValue<bool>("SmartPush:Enabled");
        if (!enabled)
        {
            _logger.LogWarning("Smart Push Notification Engine is disabled in configuration.");
            return;
        }

        var intervalSeconds = _configuration.GetValue<int>("SmartPush:ScanIntervalSeconds", 60);
        _logger.LogInformation("Smart Push Notification Engine started with scan interval of {Interval} seconds.", intervalSeconds);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Smart Push scan cycle started.");

                using (var scope = _serviceProvider.CreateScope())
                {
                    var smartPushService = scope.ServiceProvider.GetRequiredService<ISmartPushNotificationService>();
                    await smartPushService.ProcessDueUsersAsync(DateTime.UtcNow, stoppingToken);
                }

                _logger.LogInformation("Smart Push scan cycle completed.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An unhandled exception occurred in Smart Push Notification Worker cycle.");
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

        _logger.LogInformation("Smart Push Notification Engine stopped.");
    }
}
