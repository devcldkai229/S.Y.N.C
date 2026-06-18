using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Ports;
using Order.Domain.Enums;
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

    public Task<DriverLocationResult?> GetDriverLocationAsync(
        DriverLocationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.CurrentStatus is DeliveryStatus.Completed or DeliveryStatus.Cancelled or DeliveryStatus.Failed)
            return Task.FromResult<DriverLocationResult?>(null);

        if (!_settings.Enabled)
            return Task.FromResult(SimulateSandboxLocation(request));

        _logger.LogDebug("Lalamove getDriverLocation for {ExternalId}", request.ExternalDeliveryId);
        return Task.FromResult(SimulateSandboxLocation(request));
    }

    private static DriverLocationResult? SimulateSandboxLocation(DriverLocationRequest request)
    {
        var pickupLat = (double)(request.PickupLat ?? 10.7769m);
        var pickupLng = (double)(request.PickupLng ?? 106.7009m);
        var dropLat = (double)(request.DeliveryLat ?? (decimal)(pickupLat + 0.02));
        var dropLng = (double)(request.DeliveryLng ?? (decimal)(pickupLng + 0.02));

        var now = DateTimeOffset.UtcNow;
        double lat;
        double lng;

        if (request.CurrentStatus is DeliveryStatus.PickedUp or DeliveryStatus.Delivering)
        {
            var start = request.PickedUpAt ?? request.AssignedAt ?? now.AddMinutes(-5);
            var elapsed = Math.Clamp((now - start).TotalMinutes / 12.0, 0, 1);
            lat = pickupLat + (dropLat - pickupLat) * elapsed;
            lng = pickupLng + (dropLng - pickupLng) * elapsed;
        }
        else if (request.CurrentStatus is DeliveryStatus.HeadingToPickup or DeliveryStatus.Assigned)
        {
            var start = request.AssignedAt ?? now.AddMinutes(-3);
            var elapsed = Math.Clamp((now - start).TotalMinutes / 6.0, 0, 1);
            var baseLat = (double)(request.LastKnownLat ?? (decimal)(pickupLat - 0.01));
            var baseLng = (double)(request.LastKnownLng ?? (decimal)(pickupLng - 0.01));
            lat = baseLat + (pickupLat - baseLat) * elapsed;
            lng = baseLng + (pickupLng - baseLng) * elapsed;
        }
        else
        {
            return null;
        }

        return new DriverLocationResult
        {
            Found = true,
            Latitude = (decimal)lat,
            Longitude = (decimal)lng,
            UpdatedAt = now,
        };
    }

    public DeliveryWebhookPayload? ParseAndVerifyWebhook(string rawBody, string? signatureHeader)
    {
        if (!VerifySignature(rawBody, signatureHeader))
            return null;

        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;

            var eventId = GetString(root, "eventId", "id") ?? Guid.NewGuid().ToString("N");
            var eventType = GetString(root, "eventType", "type") ?? "unknown";

            JsonElement data = root;
            if (root.TryGetProperty("data", out var dataEl))
                data = dataEl;

            JsonElement orderEl = data;
            if (data.TryGetProperty("order", out var nestedOrder))
                orderEl = nestedOrder;

            var externalId = GetString(orderEl, "orderId", "id")
                ?? GetString(data, "orderId", "id")
                ?? GetString(root, "orderId");

            var status = GetString(orderEl, "status")
                ?? GetString(data, "status")
                ?? GetString(root, "status");

            JsonElement? driverEl = null;
            if (orderEl.TryGetProperty("driver", out var driver))
                driverEl = driver;
            else if (data.TryGetProperty("driver", out var driver2))
                driverEl = driver2;

            var lat = TryGetDecimal(orderEl, "lat", "latitude")
                ?? TryGetDecimal(data, "lat", "latitude")
                ?? TryGetDecimal(root, "lat", "latitude")
                ?? (driverEl.HasValue ? TryGetDecimal(driverEl.Value, "lat", "latitude") : null);
            var lng = TryGetDecimal(orderEl, "lng", "longitude", "lon")
                ?? TryGetDecimal(data, "lng", "longitude", "lon")
                ?? TryGetDecimal(root, "lng", "longitude", "lon")
                ?? (driverEl.HasValue ? TryGetDecimal(driverEl.Value, "lng", "longitude", "lon") : null);

            return new DeliveryWebhookPayload
            {
                EventId = eventId,
                EventType = eventType,
                ExternalDeliveryId = externalId,
                Status = status,
                Latitude = lat,
                Longitude = lng,
                ShipperName = driverEl.HasValue ? GetString(driverEl.Value, "name", "driverName") : null,
                ShipperPhone = driverEl.HasValue ? GetString(driverEl.Value, "phone", "driverPhone") : null,
                ShipperPlateNumber = driverEl.HasValue ? GetString(driverEl.Value, "plateNumber", "plate") : null,
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
        var provided = signatureHeader.Trim();
        if (provided.StartsWith("sha256=", StringComparison.OrdinalIgnoreCase))
            provided = provided[7..];

        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(computed),
            Encoding.UTF8.GetBytes(provided.ToLowerInvariant()));
    }

    private static string? GetString(JsonElement el, params string[] names)
    {
        foreach (var name in names)
        {
            if (el.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String)
                return prop.GetString();
        }

        return null;
    }

    private static decimal? TryGetDecimal(JsonElement el, params string[] names)
    {
        foreach (var name in names)
        {
            if (!el.TryGetProperty(name, out var prop))
                continue;
            if (prop.ValueKind == JsonValueKind.Number && prop.TryGetDecimal(out var d))
                return d;
        }

        return null;
    }
}
