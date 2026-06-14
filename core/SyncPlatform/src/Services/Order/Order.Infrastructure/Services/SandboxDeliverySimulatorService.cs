using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Services;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Services;

/// <summary>Advances sandbox-* deliveries through Ahamove-like status callbacks for local demos.</summary>
public sealed class SandboxDeliverySimulatorService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly OrderSettings _settings;
    private readonly ILogger<SandboxDeliverySimulatorService> _logger;

    public SandboxDeliverySimulatorService(
        IServiceScopeFactory scopeFactory,
        IOptions<OrderSettings> settings,
        ILogger<SandboxDeliverySimulatorService> logger)
    {
        _scopeFactory = scopeFactory;
        _settings = settings.Value;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_settings.SimulateDeliveryProgress)
            return;

        var delay = TimeSpan.FromSeconds(Math.Max(12, _settings.SandboxSimulationIntervalSeconds));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var tracking = scope.ServiceProvider.GetRequiredService<IDeliveryTrackingService>();
                await tracking.AdvanceSandboxDeliveriesAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Sandbox delivery simulation cycle failed");
            }

            await Task.Delay(delay, stoppingToken);
        }
    }
}
