using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Ports;
using Order.Domain.Enums;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Delivery;

public sealed class AhamoveAdapter : IDeliveryProvider
{
    private readonly AhamoveSettings _settings;
    private readonly AhamoveTokenService _tokenService;
    private readonly HttpClient _http;
    private readonly ILogger<AhamoveAdapter> _logger;

    public AhamoveAdapter(
        IOptions<AhamoveSettings> settings,
        AhamoveTokenService tokenService,
        HttpClient http,
        ILogger<AhamoveAdapter> logger)
    {
        _settings = settings.Value;
        _tokenService = tokenService;
        _http = http;
        _logger = logger;
    }

    public string ProviderName => "Ahamove";

    public async Task<DeliveryBookingResult> CreateOrderAsync(
        DeliveryBookingRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled || _settings.UseSandboxSimulation)
        {
            _logger.LogWarning(
                "Ahamove sandbox mode for order {OrderId} — Enabled={Enabled}, UseSandboxSimulation={UseSandboxSimulation}. " +
                "Set Enabled=true and UseSandboxSimulation=false to create real Ahamove orders.",
                request.OrderId,
                _settings.Enabled,
                _settings.UseSandboxSimulation);

            return new DeliveryBookingResult
            {
                Success = true,
                ExternalDeliveryId = $"sandbox-{request.OrderId:N}",
            };
        }

        if (string.IsNullOrWhiteSpace(_settings.ApiKey))
        {
            return new DeliveryBookingResult
            {
                Success = false,
                ErrorMessage = "Ahamove ApiKey is not configured.",
            };
        }

        try
        {
            var token = await _tokenService.GetTokenAsync(cancellationToken);
            var baseUrl = AhamoveTokenService.ResolveBaseUrl(_settings.BaseUrl);
            var partnerMobile = AhamovePhone.Normalize(_settings.Mobile);
            var recipientMobile = AhamovePhone.Normalize(request.RecipientPhone);
            if (string.IsNullOrWhiteSpace(recipientMobile))
                recipientMobile = partnerMobile;

            var orderBody = new Dictionary<string, object>
            {
                ["order_time"] = 0,
                ["path"] = new object[]
                {
                    new Dictionary<string, object>
                    {
                        ["lat"] = (double)request.PickupLat,
                        ["lng"] = (double)request.PickupLng,
                        ["address"] = request.PickupAddress,
                        ["name"] = "Sync Partner",
                        ["mobile"] = partnerMobile,
                        ["remarks"] = $"Đơn {request.OrderCode}",
                    },
                    new Dictionary<string, object>
                    {
                        ["lat"] = (double)request.DeliveryLat,
                        ["lng"] = (double)request.DeliveryLng,
                        ["address"] = request.DeliveryAddress,
                        ["name"] = request.RecipientName,
                        ["mobile"] = AhamovePhone.ToLocalDisplay(recipientMobile),
                        ["tracking_number"] = request.OrderCode,
                    },
                },
                ["service_id"] = _settings.ServiceId,
                ["payment_method"] = _settings.PaymentMethod,
                ["requests"] = Array.Empty<object>(),
            };

            // Ahamove Partner API v3: POST {BaseUrl}/orders/create
            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/orders/create");
            httpRequest.Headers.TryAddWithoutValidation("Authorization", $"Bearer {token}");
            httpRequest.Content = new StringContent(
                JsonSerializer.Serialize(orderBody),
                Encoding.UTF8,
                "application/json");

            using var response = await _http.SendAsync(httpRequest, cancellationToken);
            var raw = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Ahamove create order failed ({Status}) for {OrderId}: {Body}",
                    response.StatusCode, request.OrderId, raw);
                return new DeliveryBookingResult
                {
                    Success = false,
                    ErrorMessage = $"Ahamove create order failed: {response.StatusCode}",
                };
            }

            using var doc = JsonDocument.Parse(raw);
            var externalId = doc.RootElement.TryGetProperty("_id", out var idEl) && idEl.ValueKind == JsonValueKind.String
                ? idEl.GetString()
                : null;

            if (string.IsNullOrWhiteSpace(externalId))
            {
                return new DeliveryBookingResult
                {
                    Success = false,
                    ErrorMessage = "Ahamove create order response missing _id.",
                };
            }

            _logger.LogInformation("Ahamove order {ExternalId} created for {OrderId}", externalId, request.OrderId);
            return new DeliveryBookingResult
            {
                Success = true,
                ExternalDeliveryId = externalId,
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Ahamove create order failed for {OrderId}", request.OrderId);
            return new DeliveryBookingResult
            {
                Success = false,
                ErrorMessage = ex.Message,
            };
        }
    }

    public async Task<DriverLocationResult?> GetDriverLocationAsync(
        DriverLocationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.CurrentStatus is DeliveryStatus.Completed or DeliveryStatus.Cancelled or DeliveryStatus.Failed)
            return null;

        if (!_settings.Enabled || _settings.UseSandboxSimulation || request.ExternalDeliveryId.StartsWith("sandbox-", StringComparison.Ordinal))
            return SimulateSandboxLocation(request);

        try
        {
            var token = await _tokenService.GetTokenAsync(cancellationToken);
            var baseUrl = AhamoveTokenService.ResolveBaseUrl(_settings.BaseUrl);
            using var httpRequest = new HttpRequestMessage(HttpMethod.Get, $"{baseUrl}/orders/{request.ExternalDeliveryId}");
            httpRequest.Headers.TryAddWithoutValidation("Authorization", $"Bearer {token}");

            using var response = await _http.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogDebug("Ahamove get order {ExternalId} returned {Status}", request.ExternalDeliveryId, response.StatusCode);
                return SimulateSandboxLocation(request);
            }

            var raw = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(raw);
            var coords = AhamoveLocationResolver.Resolve(doc.RootElement, request);
            if (coords == null)
                return null;

            return new DriverLocationResult
            {
                Found = true,
                Latitude = coords.Value.Lat,
                Longitude = coords.Value.Lng,
                UpdatedAt = DateTimeOffset.UtcNow,
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Ahamove getDriverLocation failed for {ExternalId}", request.ExternalDeliveryId);
            return SimulateSandboxLocation(request);
        }
    }

    public DeliveryWebhookPayload? ParseAndVerifyWebhook(string rawBody, string? signatureHeader)
    {
        if (!VerifyWebhookAuth(signatureHeader))
        {
            _logger.LogWarning("Ahamove webhook auth failed — check WebhookApiKey and apikey header.");
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;

            var externalId = GetString(root, "_id");
            var status = GetString(root, "status");
            var subStatus = GetString(root, "sub_status");

            if (string.IsNullOrWhiteSpace(externalId))
                return null;

            var eventId = BuildEventId(root, externalId, status, subStatus);
            var coords = AhamoveLocationResolver.Resolve(root);

            return new DeliveryWebhookPayload
            {
                EventId = eventId,
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = status,
                SubStatus = subStatus,
                Latitude = coords?.Lat,
                Longitude = coords?.Lng,
                ShipperName = GetString(root, "supplier_name"),
                ShipperPhone = GetString(root, "supplier_id"),
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to parse Ahamove webhook payload");
            return null;
        }
    }

    private bool VerifyWebhookAuth(string? authValue)
    {
        if (string.IsNullOrWhiteSpace(_settings.WebhookApiKey))
            return true;
        if (string.IsNullOrWhiteSpace(authValue))
            return false;

        var expected = _settings.WebhookApiKey.Trim();
        var provided = authValue.Trim();

        if (string.Equals(provided, expected, StringComparison.Ordinal))
            return true;

        if (provided.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return string.Equals(provided[7..].Trim(), expected, StringComparison.Ordinal);

        return false;
    }

    private static string BuildEventId(JsonElement root, string externalId, string? status, string? subStatus)
    {
        var accept = GetDouble(root, "accept_time");
        var board = GetDouble(root, "board_time");
        var pickup = GetDouble(root, "pickup_time");
        var complete = GetDouble(root, "complete_time");
        var cancel = GetDouble(root, "cancel_time");
        return $"{externalId}:{status}:{subStatus}:{accept}:{board}:{pickup}:{complete}:{cancel}";
    }

    private static DriverLocationResult? SimulateSandboxLocation(DriverLocationRequest request)
    {
        if (request.LastKnownLat is decimal lat && request.LastKnownLng is decimal lng)
        {
            return new DriverLocationResult
            {
                Found = true,
                Latitude = lat,
                Longitude = lng,
                UpdatedAt = DateTimeOffset.UtcNow,
            };
        }

        var pickupLat = (double)(request.PickupLat ?? 10.7769m);
        var pickupLng = (double)(request.PickupLng ?? 106.7009m);
        var (spawnLat, spawnLng) = SandboxGeoHelper.SpawnNearPickup(pickupLat, pickupLng);

        return new DriverLocationResult
        {
            Found = true,
            Latitude = (decimal)spawnLat,
            Longitude = (decimal)spawnLng,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
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

    private static double GetDouble(JsonElement el, string name) =>
        el.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.Number && prop.TryGetDouble(out var d)
            ? d
            : 0;
}

internal static class AhamoveLocationResolver
{
    public static (decimal Lat, decimal Lng)? Resolve(JsonElement order, DriverLocationRequest? pollRequest = null)
    {
        var status = GetString(order, "status")?.ToUpperInvariant() ?? string.Empty;
        var subStatus = GetString(order, "sub_status")?.ToUpperInvariant() ?? string.Empty;
        var pickup = GetPathPoint(order, 0);
        var delivery = GetPathPoint(order, 1);

        if (TryGetCoord(order, "accept_lat", "accept_lng", out var acceptLat, out var acceptLng)
            && status is "ACCEPTED" or "ASSIGNING")
        {
            if (subStatus == "BOARDED" && pickup.HasValue)
                return pickup.Value;

            if (pickup.HasValue)
            {
                var progress = ComputeProgress(order, "accept_time", "board_time", defaultMinutes: 6);
                return Interpolate(acceptLat, acceptLng, pickup.Value.Lat, pickup.Value.Lng, progress);
            }

            return (acceptLat, acceptLng);
        }

        if (status == "ACCEPTED")
        {
            if (subStatus == "BOARDED" && pickup.HasValue)
                return pickup.Value;

            var from = pollRequest?.LastKnownLat is decimal lkLat && pollRequest.LastKnownLng is decimal lkLng
                ? (Lat: lkLat, Lng: lkLng)
                : pickup ?? (Lat: (decimal)10.7769m, Lng: (decimal)106.7009m);

            if (pickup.HasValue)
            {
                var progress = ComputeProgress(order, "accept_time", "board_time", defaultMinutes: 6);
                return Interpolate(from.Lat, from.Lng, pickup.Value.Lat, pickup.Value.Lng, progress);
            }
        }

        if (status == "IN PROCESS")
        {
            if (subStatus == "COMPLETING" && delivery.HasValue)
                return delivery.Value;

            if (pickup.HasValue && delivery.HasValue)
            {
                var progress = ComputeProgress(order, "pickup_time", null, defaultMinutes: 12);
                return Interpolate(pickup.Value.Lat, pickup.Value.Lng, delivery.Value.Lat, delivery.Value.Lng, progress);
            }
        }

        if (status == "COMPLETED")
        {
            if (TryGetCoord(order, "complete_lat", "complete_lng", out var cLat, out var cLng))
                return (cLat, cLng);
            if (delivery.HasValue)
                return delivery.Value;
        }

        if (status is "ASSIGNING" or "IDLE")
        {
            if (pollRequest?.LastKnownLat is decimal lat && pollRequest.LastKnownLng is decimal lng)
                return (lat, lng);
        }

        return null;
    }

    private static double ComputeProgress(JsonElement order, string startField, string? endField, double defaultMinutes)
    {
        var startUnix = GetUnix(order, startField);
        var endUnix = endField != null ? GetUnix(order, endField) : 0;
        var nowUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        if (startUnix <= 0)
            return 0.3;

        if (endUnix > startUnix)
            return Math.Clamp((nowUnix - startUnix) / (endUnix - startUnix), 0, 1);

        var elapsedMinutes = (nowUnix - startUnix) / 60.0;
        return Math.Clamp(elapsedMinutes / defaultMinutes, 0, 1);
    }

    private static (decimal Lat, decimal Lng) Interpolate(
        decimal fromLat, decimal fromLng, decimal toLat, decimal toLng, double progress)
    {
        var t = (decimal)progress;
        return (
            fromLat + (toLat - fromLat) * t,
            fromLng + (toLng - fromLng) * t);
    }

    private static (decimal Lat, decimal Lng)? GetPathPoint(JsonElement order, int index)
    {
        if (!order.TryGetProperty("path", out var path) || path.ValueKind != JsonValueKind.Array)
            return null;
        if (index >= path.GetArrayLength())
            return null;

        var point = path[index];
        if (!TryGetCoord(point, "lat", "lng", out var lat, out var lng))
            return null;

        return (lat, lng);
    }

    private static bool TryGetCoord(JsonElement el, string latName, string lngName, out decimal lat, out decimal lng)
    {
        lat = 0;
        lng = 0;
        if (!el.TryGetProperty(latName, out var latEl) || !el.TryGetProperty(lngName, out var lngEl))
            return false;
        if (latEl.ValueKind != JsonValueKind.Number || lngEl.ValueKind != JsonValueKind.Number)
            return false;
        if (!latEl.TryGetDecimal(out lat) || !lngEl.TryGetDecimal(out lng))
            return false;
        return lat != 0 || lng != 0;
    }

    private static double GetUnix(JsonElement el, string name) =>
        el.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.Number && prop.TryGetDouble(out var d)
            ? d
            : 0;

    private static string? GetString(JsonElement el, string name) =>
        el.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String
            ? prop.GetString()
            : null;
}
