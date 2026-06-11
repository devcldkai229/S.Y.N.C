using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Ports;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Delivery;

public class LalamoveAdapter : IDeliveryProvider
{
    private readonly LalamoveSettings _settings;
    private readonly ILogger<LalamoveAdapter> _logger;
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNameCaseInsensitive = true };

    public LalamoveAdapter(IOptions<LalamoveSettings> settings, ILogger<LalamoveAdapter> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public string ProviderName => "Lalamove";

    public Task<DeliveryBookingResult> CreateOrderAsync(
        DeliveryBookingRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled)
        {
            return Task.FromResult(new DeliveryBookingResult
            {
                Success = true,
                ExternalDeliveryId = $"sandbox-{request.OrderId:N}",
            });
        }

        _logger.LogInformation("Lalamove booking requested for order {OrderId}", request.OrderId);
        return Task.FromResult(new DeliveryBookingResult
        {
            Success = true,
            ExternalDeliveryId = Guid.NewGuid().ToString("N"),
        });
    }

    public DeliveryWebhookPayload? ParseAndVerifyWebhook(string rawBody, string? signatureHeader)
    {
        if (!VerifySignature(rawBody, signatureHeader))
            return null;

        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            return new DeliveryWebhookPayload
            {
                EventId = root.TryGetProperty("eventId", out var eid) ? eid.GetString() ?? Guid.NewGuid().ToString("N") : Guid.NewGuid().ToString("N"),
                EventType = root.TryGetProperty("eventType", out var et) ? et.GetString() ?? "unknown" : "unknown",
                ExternalDeliveryId = root.TryGetProperty("orderId", out var oid) ? oid.GetString() : null,
                Status = root.TryGetProperty("status", out var st) ? st.GetString() : null,
                Latitude = root.TryGetProperty("lat", out var lat) ? lat.GetDecimal() : null,
                Longitude = root.TryGetProperty("lng", out var lng) ? lng.GetDecimal() : null,
                ShipperName = root.TryGetProperty("driverName", out var dn) ? dn.GetString() : null,
                ShipperPhone = root.TryGetProperty("driverPhone", out var dp) ? dp.GetString() : null,
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to parse Lalamove webhook payload");
            return null;
        }
    }

    private bool VerifySignature(string rawBody, string? signatureHeader)
    {
        if (string.IsNullOrEmpty(_settings.ApiSecret))
            return true;
        if (string.IsNullOrWhiteSpace(signatureHeader))
            return false;

        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_settings.ApiSecret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(rawBody));
        var computed = Convert.ToHexString(hash).ToLowerInvariant();
        return string.Equals(computed, signatureHeader, StringComparison.OrdinalIgnoreCase);
    }
}
