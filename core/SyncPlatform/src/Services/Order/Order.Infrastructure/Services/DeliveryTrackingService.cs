using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Clients;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Application.Mappers;
using Order.Application.Ports;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Domain.Models;
using Order.Infrastructure.Delivery;
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public class DeliveryTrackingService : IDeliveryTrackingService
{
    private static readonly DeliveryStatus[] ActivePollStatuses =
    [
        DeliveryStatus.Assigned,
        DeliveryStatus.HeadingToPickup,
        DeliveryStatus.ArrivedAtPickup,
        DeliveryStatus.PickedUp,
        DeliveryStatus.Delivering,
        DeliveryStatus.Arrived,
    ];

    private readonly OrderDbContext _db;
    private readonly IMarketplaceClient _marketplaceClient;
    private readonly IDeliveryProvider _deliveryProvider;
    private readonly ITrackingLocationStore _locationStore;
    private readonly ITrackingRealtimePublisher _realtimePublisher;
    private readonly INotificationClient _notificationClient;
    private readonly ICommissionService _commissionService;
    private readonly INutritionEventClient _nutritionEventClient;
    private readonly OrderSettings _settings;
    private readonly ILogger<DeliveryTrackingService> _logger;

    public DeliveryTrackingService(
        OrderDbContext db,
        IMarketplaceClient marketplaceClient,
        IDeliveryProvider deliveryProvider,
        ITrackingLocationStore locationStore,
        ITrackingRealtimePublisher realtimePublisher,
        INotificationClient notificationClient,
        ICommissionService commissionService,
        INutritionEventClient nutritionEventClient,
        IOptions<OrderSettings> settings,
        ILogger<DeliveryTrackingService> logger)
    {
        _db = db;
        _marketplaceClient = marketplaceClient;
        _deliveryProvider = deliveryProvider;
        _locationStore = locationStore;
        _realtimePublisher = realtimePublisher;
        _notificationClient = notificationClient;
        _commissionService = commissionService;
        _nutritionEventClient = nutritionEventClient;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task BookDeliveryAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Models.Order), orderId);

        var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken)
            ?? throw new BadRequestException("Partner not found for delivery booking.");

        var booking = await _deliveryProvider.CreateOrderAsync(new DeliveryBookingRequest
        {
            OrderId = order.Id,
            OrderCode = order.OrderCode,
            PickupAddress = partner.Address ?? "Partner location",
            PickupLat = (decimal)(partner.Latitude ?? 0),
            PickupLng = (decimal)(partner.Longitude ?? 0),
            DeliveryAddress = order.DeliveryAddress ?? string.Empty,
            DeliveryLat = order.DeliveryLat ?? 0,
            DeliveryLng = order.DeliveryLng ?? 0,
            RecipientName = order.RecipientName ?? string.Empty,
            RecipientPhone = order.RecipientPhone ?? string.Empty,
        }, cancellationToken);

        var tracking = await _db.DeliveryTrackings.FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken)
            ?? new DeliveryTracking { OrderId = orderId };

        tracking.Provider = _deliveryProvider.ProviderName;
        tracking.ExternalDeliveryId = booking.ExternalDeliveryId;
        tracking.Status = booking.Success ? DeliveryStatus.Assigned : DeliveryStatus.Failed;
        tracking.AssignedAt = booking.Success ? DateTimeOffset.UtcNow : tracking.AssignedAt;

        if (!booking.Success)
            _logger.LogError("Ahamove booking failed for order {OrderId}: {Error}", orderId, booking.ErrorMessage);

        if (tracking.Id == Guid.Empty)
            _db.DeliveryTrackings.Add(tracking);
        else
            tracking.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task KickoffDeliveryAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var tracking = await _db.DeliveryTrackings.FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);
        if (tracking == null)
            await BookDeliveryAsync(orderId, cancellationToken);

        tracking = await _db.DeliveryTrackings.FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);
        if (tracking == null)
            return;

        tracking.ShipperName ??= "Tài xế SYNC Demo";
        tracking.ShipperPhone ??= "0901234567";
        tracking.ShipperPlateNumber ??= "59X1-12345";
        if (tracking.Status == DeliveryStatus.Pending)
            tracking.Status = DeliveryStatus.Assigned;
        tracking.AssignedAt ??= DateTimeOffset.UtcNow;

        var order = await _db.Orders.FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);
        if (order != null && _settings.SimulateDeliveryProgress)
        {
            if (order.Status == OrderStatus.Confirmed)
                await ApplySingleOrderStatusAsync(orderId, OrderStatus.Preparing, "delivery-kickoff", cancellationToken);
            order = await _db.Orders.AsNoTracking().FirstAsync(x => x.Id == orderId, cancellationToken);
            if (order.Status == OrderStatus.Preparing)
                await ApplySingleOrderStatusAsync(orderId, OrderStatus.ReadyForPickup, "delivery-kickoff", cancellationToken);
        }

        tracking.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        await PublishStatusAsync(tracking, cancellationToken);

        if (tracking.ExternalDeliveryId?.StartsWith("sandbox-", StringComparison.OrdinalIgnoreCase) == true)
            await AdvanceSingleSandboxDeliveryAsync(tracking, cancellationToken);
    }

    public async Task AdvanceSandboxDeliveriesAsync(CancellationToken cancellationToken = default)
    {
        if (!_settings.SimulateDeliveryProgress)
            return;

        var trackings = await _db.DeliveryTrackings
            .Where(t => t.ExternalDeliveryId != null
                && t.ExternalDeliveryId.StartsWith("sandbox-")
                && t.Status != DeliveryStatus.Completed
                && t.Status != DeliveryStatus.Cancelled
                && t.Status != DeliveryStatus.Failed)
            .Take(20)
            .ToListAsync(cancellationToken);

        foreach (var tracking in trackings)
            await AdvanceSingleSandboxDeliveryAsync(tracking, cancellationToken);
    }

    private async Task AdvanceSingleSandboxDeliveryAsync(
        DeliveryTracking tracking,
        CancellationToken cancellationToken)
    {
        var entity = await _db.DeliveryTrackings
            .FirstOrDefaultAsync(x => x.Id == tracking.Id, cancellationToken);
        if (entity == null)
            return;

        var order = await _db.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == entity.OrderId, cancellationToken);
        if (order == null)
            return;

        var (pickupLat, pickupLng) = await ResolvePickupCoordinatesAsync(order, cancellationToken);
        var dropLat = (double)(order.DeliveryLat ?? (decimal)(pickupLat + 0.015));
        var dropLng = (double)(order.DeliveryLng ?? (decimal)(pickupLng + 0.012));

        if (entity.Status == DeliveryStatus.Arrived)
        {
            await PublishSandboxStatusWebhookAsync(entity, cancellationToken);
            return;
        }

        if (entity.Status == DeliveryStatus.ArrivedAtPickup)
        {
            await PublishSandboxLocationAsync(entity, pickupLat, pickupLng, cancellationToken);
            await PublishSandboxStatusWebhookAsync(entity, cancellationToken);
            return;
        }

        if (entity.Status is DeliveryStatus.Completed or DeliveryStatus.Cancelled or DeliveryStatus.Failed)
            return;

        var headingToCustomer = entity.Status is DeliveryStatus.PickedUp or DeliveryStatus.Delivering;
        var headingToPickup = entity.Status is DeliveryStatus.Assigned or DeliveryStatus.HeadingToPickup;

        if (!headingToCustomer && !headingToPickup)
            return;

        var targetLat = headingToCustomer ? dropLat : pickupLat;
        var targetLng = headingToCustomer ? dropLng : pickupLng;

        double currentLat;
        double currentLng;
        if (entity.LastKnownLat is null || entity.LastKnownLng is null)
        {
            (currentLat, currentLng) = SandboxGeoHelper.SpawnNearPickup(pickupLat, pickupLng);
            if (entity.Status == DeliveryStatus.Assigned)
            {
                entity.Status = DeliveryStatus.HeadingToPickup;
                await _db.SaveChangesAsync(cancellationToken);
                await PublishStatusAsync(entity, cancellationToken);
            }
        }
        else
        {
            currentLat = (double)entity.LastKnownLat.Value;
            currentLng = (double)entity.LastKnownLng.Value;
        }

        var (nextLat, nextLng) = SandboxGeoHelper.StepToward(currentLat, currentLng, targetLat, targetLng);
        await PublishSandboxLocationAsync(entity, nextLat, nextLng, cancellationToken);

        var distM = SandboxGeoHelper.DistanceMeters(nextLat, nextLng, targetLat, targetLng);
        if (distM >= 70)
            return;

        if (headingToPickup)
            await PublishSandboxLocationAsync(entity, pickupLat, pickupLng, cancellationToken);

        if (headingToCustomer)
            await PublishSandboxLocationAsync(entity, dropLat, dropLng, cancellationToken);

        await PublishSandboxStatusWebhookAsync(entity, cancellationToken);
    }

    private async Task PublishSandboxStatusWebhookAsync(
        DeliveryTracking tracking,
        CancellationToken cancellationToken)
    {
        var fresh = await _db.DeliveryTrackings
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == tracking.Id, cancellationToken);
        if (fresh == null)
            return;

        var payload = BuildNextSandboxWebhook(fresh);
        if (payload == null)
            return;

        await ProcessWebhookAsync(payload, "{}", cancellationToken);
    }

    private async Task PublishSandboxLocationAsync(
        DeliveryTracking tracking,
        double lat,
        double lng,
        CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        await HandleLocationUpdateAsync(tracking, (decimal)lat, (decimal)lng, now, cancellationToken);
        tracking.LastKnownLat = (decimal)lat;
        tracking.LastKnownLng = (decimal)lng;
        tracking.LastLocationUpdatedAt = now;
        tracking.UpdatedAt = now;
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<(double Lat, double Lng)> ResolvePickupCoordinatesAsync(
        Domain.Models.Order order,
        CancellationToken cancellationToken)
    {
        var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken);
        if (partner?.Latitude is not null && partner.Longitude is not null)
            return (partner.Latitude.Value, partner.Longitude.Value);

        return (10.7769, 106.7009);
    }

    private static DeliveryWebhookPayload? BuildNextSandboxWebhook(DeliveryTracking tracking)
    {
        var externalId = tracking.ExternalDeliveryId!;
        return tracking.Status switch
        {
            DeliveryStatus.Assigned => new DeliveryWebhookPayload
            {
                EventId = $"{externalId}:ACCEPTED:{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = "ACCEPTED",
                SubStatus = null,
                ShipperName = tracking.ShipperName ?? "Tài xế SYNC Demo",
                ShipperPhone = tracking.ShipperPhone ?? "0901234567",
                ShipperPlateNumber = tracking.ShipperPlateNumber ?? "59X1-12345",
            },
            DeliveryStatus.HeadingToPickup => new DeliveryWebhookPayload
            {
                EventId = $"{externalId}:BOARDED:{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = "ACCEPTED",
                SubStatus = "BOARDED",
            },
            DeliveryStatus.ArrivedAtPickup => new DeliveryWebhookPayload
            {
                EventId = $"{externalId}:INPROCESS:{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = "IN PROCESS",
                SubStatus = null,
            },
            DeliveryStatus.PickedUp or DeliveryStatus.Delivering => new DeliveryWebhookPayload
            {
                EventId = $"{externalId}:COMPLETING:{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = "IN PROCESS",
                SubStatus = "COMPLETING",
            },
            DeliveryStatus.Arrived => new DeliveryWebhookPayload
            {
                EventId = $"{externalId}:COMPLETED:{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                EventType = "ORDER_CALLBACK",
                ExternalDeliveryId = externalId,
                Status = "COMPLETED",
                SubStatus = null,
            },
            _ => null,
        };
    }

    public async Task<DeliveryTrackingDto?> GetTrackingAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var tracking = await _db.DeliveryTrackings.AsNoTracking()
            .FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);
        if (tracking == null)
            return null;

        var order = await _db.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

        var live = await _locationStore.GetLiveLocationAsync(orderId, cancellationToken);
        var dto = tracking.ToDto();
        dto.OrderStatus = order?.Status;
        dto.EtaMinutes = ComputeEtaMinutes(tracking.EstimatedArrivalAt);

        if (order != null)
        {
            var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken);
            if (partner?.Latitude is not null && partner.Longitude is not null)
            {
                dto.PickupLat = (decimal)partner.Latitude.Value;
                dto.PickupLng = (decimal)partner.Longitude.Value;
            }
        }

        if (live != null)
        {
            dto.LastKnownLat = live.Latitude;
            dto.LastKnownLng = live.Longitude;
            dto.LastLocationUpdatedAt = live.UpdatedAt;
        }
        else if (tracking.LastKnownLat is not null && tracking.LastKnownLng is not null)
        {
            dto.LastKnownLat = tracking.LastKnownLat;
            dto.LastKnownLng = tracking.LastKnownLng;
            dto.LastLocationUpdatedAt = tracking.LastLocationUpdatedAt;
        }
        else if (order != null
            && tracking.ExternalDeliveryId?.StartsWith("sandbox-", StringComparison.OrdinalIgnoreCase) == true)
        {
            var simulated = await _deliveryProvider.GetDriverLocationAsync(new DriverLocationRequest
            {
                ExternalDeliveryId = tracking.ExternalDeliveryId!,
                CurrentStatus = tracking.Status,
                PickupLat = dto.PickupLat,
                PickupLng = dto.PickupLng,
                DeliveryLat = order.DeliveryLat,
                DeliveryLng = order.DeliveryLng,
                LastKnownLat = tracking.LastKnownLat,
                LastKnownLng = tracking.LastKnownLng,
                AssignedAt = tracking.AssignedAt,
                PickedUpAt = tracking.PickedUpAt,
            }, cancellationToken);

            if (simulated is { Found: true })
            {
                dto.LastKnownLat = simulated.Latitude;
                dto.LastKnownLng = simulated.Longitude;
                dto.LastLocationUpdatedAt = simulated.UpdatedAt;
            }
        }

        dto.StatusMessage = BuildStatusMessage(tracking.Status);

        return dto;
    }

    public async Task ProcessWebhookAsync(
        DeliveryWebhookPayload payload,
        string rawPayloadJson,
        CancellationToken cancellationToken = default)
    {
        var existing = await _db.DeliveryWebhookEvents
            .FirstOrDefaultAsync(x => x.Provider == _deliveryProvider.ProviderName && x.ExternalEventId == payload.EventId, cancellationToken);

        if (existing?.Processed == true)
            return;

        existing ??= new DeliveryWebhookEvent
        {
            Provider = _deliveryProvider.ProviderName,
            ExternalEventId = payload.EventId,
            EventType = payload.EventType,
            PayloadJson = rawPayloadJson,
        };

        if (existing.Id == Guid.Empty)
            _db.DeliveryWebhookEvents.Add(existing);

        try
        {
            DeliveryTracking? tracking = null;
            if (!string.IsNullOrWhiteSpace(payload.ExternalDeliveryId))
            {
                tracking = await _db.DeliveryTrackings
                    .FirstOrDefaultAsync(x => x.ExternalDeliveryId == payload.ExternalDeliveryId, cancellationToken);
            }

            if (tracking != null)
            {
                await HandleWebhookEventAsync(tracking, payload, cancellationToken);
            }
            else
            {
                _logger.LogWarning(
                    "Ahamove webhook {EventType} ignored — tracking not found for {ExternalId}",
                    payload.EventType,
                    payload.ExternalDeliveryId);
            }

            existing.Processed = true;
            existing.ProcessedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            existing.ErrorMessage = ex.Message;
            await _db.SaveChangesAsync(cancellationToken);
            throw;
        }
    }

    public async Task PollActiveLocationsAsync(CancellationToken cancellationToken = default)
    {
        var active = await _db.DeliveryTrackings
            .Where(x => ActivePollStatuses.Contains(x.Status) && x.ExternalDeliveryId != null)
            .Take(50)
            .ToListAsync(cancellationToken);

        foreach (var tracking in active)
        {
            cancellationToken.ThrowIfCancellationRequested();

            if (tracking.ExternalDeliveryId?.StartsWith("sandbox-", StringComparison.OrdinalIgnoreCase) == true)
                continue;

            var order = await _db.Orders.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == tracking.OrderId, cancellationToken);
            if (order == null)
                continue;

            decimal? pickupLat = null;
            decimal? pickupLng = null;
            var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken);
            if (partner?.Latitude is not null && partner.Longitude is not null)
            {
                pickupLat = (decimal)partner.Latitude.Value;
                pickupLng = (decimal)partner.Longitude.Value;
            }

            var location = await _deliveryProvider.GetDriverLocationAsync(new DriverLocationRequest
            {
                ExternalDeliveryId = tracking.ExternalDeliveryId!,
                CurrentStatus = tracking.Status,
                PickupLat = pickupLat,
                PickupLng = pickupLng,
                DeliveryLat = order.DeliveryLat,
                DeliveryLng = order.DeliveryLng,
                LastKnownLat = tracking.LastKnownLat,
                LastKnownLng = tracking.LastKnownLng,
                AssignedAt = tracking.AssignedAt,
                PickedUpAt = tracking.PickedUpAt,
            }, cancellationToken);

            if (location is not { Found: true })
                continue;

            await HandleLocationUpdateAsync(tracking, location.Latitude, location.Longitude, location.UpdatedAt, cancellationToken);
        }
    }

    private async Task HandleWebhookEventAsync(
        DeliveryTracking tracking,
        DeliveryWebhookPayload payload,
        CancellationToken cancellationToken)
    {
        switch (payload.EventType.ToUpperInvariant())
        {
            case "DRIVER_ASSIGNED":
                tracking.ShipperName = payload.ShipperName ?? tracking.ShipperName;
                tracking.ShipperPhone = payload.ShipperPhone ?? tracking.ShipperPhone;
                tracking.ShipperPlateNumber = payload.ShipperPlateNumber ?? tracking.ShipperPlateNumber;
                if (tracking.Status == DeliveryStatus.Pending)
                    tracking.Status = DeliveryStatus.Assigned;
                tracking.AssignedAt ??= DateTimeOffset.UtcNow;
                await _db.SaveChangesAsync(cancellationToken);
                await PublishStatusAsync(tracking, cancellationToken);
                await NotifyStatusAsync(tracking, "DRIVER_ASSIGNED", payload.Status, cancellationToken);
                break;

            case "ORDER_STATUS_CHANGED":
                if (!string.IsNullOrWhiteSpace(payload.Status))
                    await HandleStatusUpdateAsync(tracking, payload, cancellationToken);
                break;

            case "POD_STATUS_CHANGED":
            case "POP_STATUS_CHANGED":
                if (!string.IsNullOrWhiteSpace(payload.Status) &&
                    payload.Status.Equals("COMPLETED", StringComparison.OrdinalIgnoreCase))
                {
                    payload.Status = "COMPLETED";
                    await HandleStatusUpdateAsync(tracking, payload, cancellationToken);
                }
                break;

            default:
                if (!string.IsNullOrWhiteSpace(payload.Status))
                    await HandleStatusUpdateAsync(tracking, payload, cancellationToken);
                break;
        }

        await TryApplyWebhookLocationAsync(tracking, payload, cancellationToken);
    }

    private async Task TryApplyWebhookLocationAsync(
        DeliveryTracking tracking,
        DeliveryWebhookPayload payload,
        CancellationToken cancellationToken)
    {
        if (payload.Latitude is not decimal lat || payload.Longitude is not decimal lng)
            return;

        var updatedAt = DateTimeOffset.UtcNow;
        await HandleLocationUpdateAsync(tracking, lat, lng, updatedAt, cancellationToken);
    }

    private async Task HandleLocationUpdateAsync(
        DeliveryTracking tracking,
        decimal lat,
        decimal lng,
        DateTimeOffset updatedAt,
        CancellationToken cancellationToken)
    {
        var update = new TrackingLocationUpdateDto
        {
            OrderId = tracking.OrderId,
            Latitude = lat,
            Longitude = lng,
            UpdatedAt = updatedAt,
        };

        await _locationStore.SetLiveLocationAsync(
            tracking.OrderId, lat, lng, TimeSpan.FromMinutes(15), cancellationToken);
        await _locationStore.PublishLocationUpdateAsync(update, cancellationToken);
        await _realtimePublisher.PublishLocationAsync(update, cancellationToken);

        var shouldPersist = tracking.LastLocationUpdatedAt == null
            || tracking.LastLocationUpdatedAt.Value.AddSeconds(_settings.LocationPersistIntervalSeconds) <= DateTimeOffset.UtcNow;

        if (shouldPersist)
        {
            tracking.LastKnownLat = lat;
            tracking.LastKnownLng = lng;
            tracking.LastLocationUpdatedAt = updatedAt;
            tracking.UpdatedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task HandleStatusUpdateAsync(
        DeliveryTracking tracking,
        DeliveryWebhookPayload payload,
        CancellationToken cancellationToken)
    {
        var previousDeliveryStatus = tracking.Status;
        var deliveryStatus = MapAhamoveStatus(payload.Status!, payload.SubStatus, tracking.Status);
        tracking.Status = deliveryStatus;
        tracking.ShipperName = payload.ShipperName ?? tracking.ShipperName;
        tracking.ShipperPhone = payload.ShipperPhone ?? tracking.ShipperPhone;
        tracking.ShipperPlateNumber = payload.ShipperPlateNumber ?? tracking.ShipperPlateNumber;

        if (deliveryStatus == DeliveryStatus.PickedUp)
            tracking.PickedUpAt ??= DateTimeOffset.UtcNow;
        if (deliveryStatus == DeliveryStatus.Completed)
            tracking.DeliveredAt ??= DateTimeOffset.UtcNow;

        if (deliveryStatus is DeliveryStatus.Delivering or DeliveryStatus.PickedUp)
        {
            tracking.EstimatedArrivalAt ??= DateTimeOffset.UtcNow.AddMinutes(15);
        }

        await _db.SaveChangesAsync(cancellationToken);

        var orderStatus = MapOrderStatus(deliveryStatus);
        if (orderStatus.HasValue)
            await ApplyOrderStatusAsync(tracking.OrderId, orderStatus.Value, payload.Status, cancellationToken);

        if (previousDeliveryStatus != deliveryStatus)
        {
            await PublishStatusAsync(tracking, cancellationToken);
            await NotifyStatusAsync(tracking, payload.EventType, payload.Status, cancellationToken);
        }
    }

    private async Task PublishStatusAsync(DeliveryTracking tracking, CancellationToken cancellationToken)
    {
        var order = await _db.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == tracking.OrderId, cancellationToken);

        var update = new TrackingStatusUpdateDto
        {
            OrderId = tracking.OrderId,
            OrderStatus = order?.Status,
            DeliveryStatus = tracking.Status,
            EtaMinutes = ComputeEtaMinutes(tracking.EstimatedArrivalAt),
            ShipperName = tracking.ShipperName,
            ShipperPhone = tracking.ShipperPhone,
            ShipperPlateNumber = tracking.ShipperPlateNumber,
            StatusMessage = BuildStatusMessage(tracking.Status),
            UpdatedAt = DateTimeOffset.UtcNow,
        };

        await _realtimePublisher.PublishStatusAsync(update, cancellationToken);
    }

    private async Task ApplyOrderStatusAsync(
        Guid orderId,
        OrderStatus toStatus,
        string? note,
        CancellationToken cancellationToken)
    {
        foreach (var step in BuildTransitionChain(orderId, toStatus))
        {
            await ApplySingleOrderStatusAsync(orderId, step, note, cancellationToken);
        }
    }

    private async Task ApplySingleOrderStatusAsync(
        Guid orderId,
        OrderStatus toStatus,
        string? note,
        CancellationToken cancellationToken)
    {
        var order = await _db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        if (order == null || order.Status == toStatus)
            return;
        if (!CanDeliveryTransition(order.Status, toStatus))
            return;

        var from = order.Status;
        order.Status = toStatus;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        if (toStatus == OrderStatus.Delivered)
            order.CompletedAt = null;

        _db.OrderStatusHistories.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = from,
            ToStatus = toStatus,
            ChangedBy = "ahamove-webhook",
            Note = note,
        });
        await _db.SaveChangesAsync(cancellationToken);

        if (toStatus == OrderStatus.Delivered)
        {
            order.Status = OrderStatus.Completed;
            order.CompletedAt = DateTimeOffset.UtcNow;
            _db.OrderStatusHistories.Add(new OrderStatusHistory
            {
                OrderId = order.Id,
                FromStatus = OrderStatus.Delivered,
                ToStatus = OrderStatus.Completed,
                ChangedBy = "system",
                Note = "Auto-complete after delivery",
            });
            await _db.SaveChangesAsync(cancellationToken);
            await _commissionService.CreateFoodDeliveryCommissionAsync(order.Id, cancellationToken);
            await PublishOrderCompletedAsync(order, cancellationToken);
        }
    }

    private static IEnumerable<OrderStatus> BuildTransitionChain(Guid orderId, OrderStatus target)
    {
        _ = orderId;
        return target switch
        {
            OrderStatus.Delivering =>
            [
                OrderStatus.PickedUp,
                OrderStatus.Delivering,
            ],
            OrderStatus.Delivered =>
            [
                OrderStatus.PickedUp,
                OrderStatus.Delivering,
                OrderStatus.Delivered,
            ],
            _ => [target],
        };
    }

    private async Task NotifyStatusAsync(
        DeliveryTracking tracking,
        string eventType,
        string? providerStatus,
        CancellationToken cancellationToken)
    {
        var order = await _db.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == tracking.OrderId, cancellationToken);
        if (order == null)
            return;

        var message = BuildNotificationMessage(eventType, providerStatus, tracking.Status);
        await _notificationClient.SendOrderStatusAsync(
            order.UserId,
            "Cập nhật đơn hàng",
            message,
            order.Id,
            cancellationToken);
    }

    private async Task PublishOrderCompletedAsync(Domain.Models.Order order, CancellationToken cancellationToken)
    {
        var validated = await _marketplaceClient.ValidateOrderItemsAsync(new ValidateOrderItemsRequest
        {
            PartnerId = order.PartnerId,
            FoodMenuItemIds = order.Items.Select(i => i.FoodMenuItemId).ToList(),
        }, cancellationToken);

        var nutritionById = validated.Items.ToDictionary(x => x.FoodMenuItemId);
        await _nutritionEventClient.PublishOrderCompletedAsync(new Contract.Events.OrderCompletedEvent
        {
            OrderId = order.Id,
            UserId = order.UserId,
            CompletedAt = order.CompletedAt ?? DateTimeOffset.UtcNow,
            Items = order.Items.Select(i =>
            {
                nutritionById.TryGetValue(i.FoodMenuItemId, out var menu);
                return new Contract.Events.OrderCompletedLineItem
                {
                    FoodMenuItemId = i.FoodMenuItemId,
                    NameSnapshot = i.NameSnapshot,
                    Quantity = i.Quantity,
                    Calories = menu?.Calories ?? 0,
                    ProteinGram = menu?.ProteinGram ?? 0,
                    CarbGram = menu?.CarbGram ?? 0,
                    FatGram = menu?.FatGram ?? 0,
                };
            }).ToList(),
        }, cancellationToken);
    }

    private static bool CanDeliveryTransition(OrderStatus from, OrderStatus to)
    {
        if (to == OrderStatus.Cancelled)
            return from is not (OrderStatus.Completed or OrderStatus.Refunded);

        if (to is OrderStatus.Preparing or OrderStatus.ReadyForPickup)
            return Application.Helpers.OrderStatusStateMachine.CanTransition(from, to);

        return Application.Helpers.OrderStatusStateMachine.CanSystemTransition(from, to);
    }

    private static DeliveryStatus MapAhamoveStatus(string status, string? subStatus, DeliveryStatus current)
    {
        var normalized = status.ToUpperInvariant();
        var sub = subStatus?.ToUpperInvariant() ?? string.Empty;

        return normalized switch
        {
            "IDLE" => DeliveryStatus.Pending,
            "ASSIGNING" => DeliveryStatus.Assigned,
            "ACCEPTED" when sub == "BOARDED" => DeliveryStatus.ArrivedAtPickup,
            "ACCEPTED" => current >= DeliveryStatus.ArrivedAtPickup
                ? DeliveryStatus.ArrivedAtPickup
                : DeliveryStatus.HeadingToPickup,
            "IN PROCESS" when sub == "COMPLETING" => DeliveryStatus.Arrived,
            "IN PROCESS" => DeliveryStatus.Delivering,
            "COMPLETED" => DeliveryStatus.Completed,
            "CANCELLED" or "CANCELED" => DeliveryStatus.Cancelled,
            _ => current,
        };
    }

    private static OrderStatus? MapOrderStatus(DeliveryStatus status) => status switch
    {
        DeliveryStatus.Assigned or DeliveryStatus.HeadingToPickup or DeliveryStatus.ArrivedAtPickup
            => OrderStatus.Preparing,
        DeliveryStatus.PickedUp => OrderStatus.PickedUp,
        DeliveryStatus.Delivering or DeliveryStatus.Arrived => OrderStatus.Delivering,
        DeliveryStatus.Completed => OrderStatus.Delivered,
        DeliveryStatus.Cancelled or DeliveryStatus.Failed => OrderStatus.Cancelled,
        _ => null,
    };

    private static int? ComputeEtaMinutes(DateTimeOffset? estimatedArrivalAt)
    {
        if (estimatedArrivalAt == null)
            return null;

        var minutes = (int)Math.Ceiling((estimatedArrivalAt.Value - DateTimeOffset.UtcNow).TotalMinutes);
        return Math.Max(0, minutes);
    }

    private static string BuildStatusMessage(DeliveryStatus status) => status switch
    {
        DeliveryStatus.Assigned => "Đã tìm thấy tài xế cho đơn của bạn",
        DeliveryStatus.HeadingToPickup => "Tài xế đang đến lấy hàng",
        DeliveryStatus.ArrivedAtPickup => "Tài xế đã đến điểm lấy hàng",
        DeliveryStatus.PickedUp => "Shipper đã lấy hàng, đang đến chỗ bạn",
        DeliveryStatus.Delivering => "Đơn đang trên đường tới bạn",
        DeliveryStatus.Arrived => "Tài xế đã đến gần địa chỉ giao hàng",
        DeliveryStatus.Completed => "Đơn đã giao thành công",
        DeliveryStatus.Cancelled => "Đơn giao hàng đã bị huỷ",
        DeliveryStatus.Failed => "Không thể giao đơn hàng",
        _ => "Đang cập nhật trạng thái giao hàng",
    };

    private static string BuildNotificationMessage(string eventType, string? providerStatus, DeliveryStatus deliveryStatus)
    {
        if (eventType.Equals("DRIVER_ASSIGNED", StringComparison.OrdinalIgnoreCase))
            return "Đã tìm thấy tài xế cho đơn của bạn 🛵";

        var status = providerStatus?.ToUpperInvariant() ?? deliveryStatus.ToString();
        return status switch
        {
            "ASSIGNING" or "IDLE" => "Đang tìm tài xế cho đơn của bạn",
            "ACCEPTED" => deliveryStatus >= DeliveryStatus.ArrivedAtPickup
                ? "Tài xế đã đến điểm lấy hàng"
                : "Đã tìm thấy tài xế, đang đến lấy hàng 🛵",
            "IN PROCESS" => deliveryStatus >= DeliveryStatus.Arrived
                ? "Tài xế đã đến gần địa chỉ giao hàng"
                : "Shipper đã lấy hàng, đang đến chỗ bạn",
            "COMPLETED" => "Đơn đã giao thành công 🎉",
            "CANCELLED" or "CANCELED" => "Đơn giao hàng của bạn đã bị huỷ",
            _ => BuildStatusMessage(deliveryStatus),
        };
    }
}
