using System.Text.Json;
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
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public class DeliveryTrackingService : IDeliveryTrackingService
{
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
        tracking.Status = booking.Success ? DeliveryStatus.Assigned : DeliveryStatus.Pending;
        tracking.AssignedAt = DateTimeOffset.UtcNow;

        if (tracking.Id == Guid.Empty)
            _db.DeliveryTrackings.Add(tracking);
        else
            tracking.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<DeliveryTrackingDto?> GetTrackingAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var tracking = await _db.DeliveryTrackings.AsNoTracking()
            .FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);
        if (tracking == null)
            return null;

        var live = await _locationStore.GetLiveLocationAsync(orderId, cancellationToken);
        var dto = tracking.ToDto();
        if (live != null)
        {
            dto.LastKnownLat = live.Latitude;
            dto.LastKnownLng = live.Longitude;
            dto.LastLocationUpdatedAt = live.UpdatedAt;
        }

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
            var tracking = await _db.DeliveryTrackings
                .FirstOrDefaultAsync(x => x.ExternalDeliveryId == payload.ExternalDeliveryId, cancellationToken);

            if (tracking != null)
            {
                if (payload.Latitude is not null && payload.Longitude is not null)
                    await HandleLocationUpdateAsync(tracking, payload.Latitude.Value, payload.Longitude.Value, cancellationToken);

                if (!string.IsNullOrWhiteSpace(payload.Status))
                    await HandleStatusUpdateAsync(tracking, payload, cancellationToken);
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

    private async Task HandleLocationUpdateAsync(
        DeliveryTracking tracking,
        decimal lat,
        decimal lng,
        CancellationToken cancellationToken)
    {
        var update = new TrackingLocationUpdateDto
        {
            OrderId = tracking.OrderId,
            Latitude = lat,
            Longitude = lng,
            UpdatedAt = DateTimeOffset.UtcNow,
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
            tracking.LastLocationUpdatedAt = update.UpdatedAt;
            tracking.UpdatedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task HandleStatusUpdateAsync(
        DeliveryTracking tracking,
        DeliveryWebhookPayload payload,
        CancellationToken cancellationToken)
    {
        var deliveryStatus = MapDeliveryStatus(payload.Status!);
        tracking.Status = deliveryStatus;
        tracking.ShipperName = payload.ShipperName ?? tracking.ShipperName;
        tracking.ShipperPhone = payload.ShipperPhone ?? tracking.ShipperPhone;
        tracking.ShipperPlateNumber = payload.ShipperPlateNumber ?? tracking.ShipperPlateNumber;

        if (deliveryStatus == DeliveryStatus.PickedUp)
            tracking.PickedUpAt = DateTimeOffset.UtcNow;
        if (deliveryStatus == DeliveryStatus.Completed)
            tracking.DeliveredAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var orderStatus = MapOrderStatus(deliveryStatus);
        if (orderStatus.HasValue)
            await ApplyOrderStatusAsync(tracking.OrderId, orderStatus.Value, payload.Status, cancellationToken);
    }

    private async Task ApplyOrderStatusAsync(
        Guid orderId,
        OrderStatus toStatus,
        string? note,
        CancellationToken cancellationToken)
    {
        var order = await _db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        if (order == null || order.Status == toStatus)
            return;
        if (!Application.Helpers.OrderStatusStateMachine.CanSystemTransition(order.Status, toStatus))
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
            ChangedBy = "lalamove-webhook",
            Note = note,
        });
        await _db.SaveChangesAsync(cancellationToken);

        await _notificationClient.SendOrderStatusAsync(
            order.UserId,
            "Cập nhật giao hàng",
            $"Đơn {order.OrderCode}: {from} → {toStatus}",
            order.Id,
            cancellationToken);

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

    private static DeliveryStatus MapDeliveryStatus(string status) => status.ToUpperInvariant() switch
    {
        "ASSIGNING_DRIVER" or "ASSIGNED" => DeliveryStatus.Assigned,
        "ON_GOING" or "PICKED_UP" => DeliveryStatus.PickedUp,
        "DELIVERING" => DeliveryStatus.Delivering,
        "COMPLETED" or "DELIVERED" => DeliveryStatus.Completed,
        "CANCELLED" => DeliveryStatus.Cancelled,
        _ => DeliveryStatus.Delivering,
    };

    private static OrderStatus? MapOrderStatus(DeliveryStatus status) => status switch
    {
        DeliveryStatus.PickedUp => OrderStatus.PickedUp,
        DeliveryStatus.Delivering => OrderStatus.Delivering,
        DeliveryStatus.Completed => OrderStatus.Delivered,
        _ => null,
    };
}
