using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Services;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Services;

public sealed class DeliveryLocationPollerService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly OrderSettings _settings;
    private readonly ILogger<DeliveryLocationPollerService> _logger;

    public DeliveryLocationPollerService(
        IServiceScopeFactory scopeFactory,
        IOptions<OrderSettings> settings,
        ILogger<DeliveryLocationPollerService> logger)
    {
        _scopeFactory = scopeFactory;
        _settings = settings.Value;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var delay = TimeSpan.FromSeconds(Math.Max(10, _settings.LocationPollIntervalSeconds));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var tracking = scope.ServiceProvider.GetRequiredService<IDeliveryTrackingService>();
                await tracking.PollActiveLocationsAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Delivery location poll cycle failed");
            }

            await Task.Delay(delay, stoppingToken);
        }
    }
}
