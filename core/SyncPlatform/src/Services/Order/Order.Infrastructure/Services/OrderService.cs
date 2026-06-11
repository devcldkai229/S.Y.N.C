using Contract.Events;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.Clients;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Application.Helpers;
using Order.Application.Mappers;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Domain.Models;
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public class OrderService : IOrderService
{
    private readonly OrderDbContext _db;
    private readonly IMarketplaceClient _marketplaceClient;
    private readonly IPaymentClient _paymentClient;
    private readonly INotificationClient _notificationClient;
    private readonly INutritionEventClient _nutritionEventClient;
    private readonly ICommissionService _commissionService;
    private readonly IDeliveryTrackingService _deliveryTrackingService;
    private readonly OrderSettings _settings;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        OrderDbContext db,
        IMarketplaceClient marketplaceClient,
        IPaymentClient paymentClient,
        INotificationClient notificationClient,
        INutritionEventClient nutritionEventClient,
        ICommissionService commissionService,
        IDeliveryTrackingService deliveryTrackingService,
        IOptions<OrderSettings> settings,
        ILogger<OrderService> logger)
    {
        _db = db;
        _marketplaceClient = marketplaceClient;
        _paymentClient = paymentClient;
        _notificationClient = notificationClient;
        _nutritionEventClient = nutritionEventClient;
        _commissionService = commissionService;
        _deliveryTrackingService = deliveryTrackingService;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<OrderDto> PlaceOrderAsync(
        Guid userId,
        PlaceOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Items.Count == 0)
            throw new BadRequestException("At least one item is required.");
        if (!string.IsNullOrWhiteSpace(dto.ClientRequestKey))
        {
            var existing = await _db.OrderIdempotencyKeys
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.UserId == userId && x.ClientRequestKey == dto.ClientRequestKey,
                    cancellationToken);
            if (existing != null)
            {
                var existingOrder = await LoadOrderAsync(existing.OrderId, cancellationToken);
                return existingOrder.ToDto();
            }
        }

        var validation = await _marketplaceClient.ValidateOrderItemsAsync(new ValidateOrderItemsRequest
        {
            PartnerId = dto.PartnerId,
            FoodMenuItemIds = dto.Items.Select(i => i.FoodMenuItemId).ToList(),
        }, cancellationToken);

        if (!validation.IsValid)
            throw new BadRequestException(validation.ErrorMessage ?? "Order items validation failed.");

        var validatedById = validation.Items.ToDictionary(x => x.FoodMenuItemId);
        decimal subtotal = 0;
        var orderItems = new List<OrderItem>();
        foreach (var line in dto.Items)
        {
            if (line.Quantity <= 0)
                throw new BadRequestException("Quantity must be greater than zero.");
            if (!validatedById.TryGetValue(line.FoodMenuItemId, out var menu))
                throw new BadRequestException($"Food menu item {line.FoodMenuItemId} is invalid.");

            var lineSubtotal = menu.Price * line.Quantity;
            subtotal += lineSubtotal;
            orderItems.Add(new OrderItem
            {
                FoodMenuItemId = menu.FoodMenuItemId,
                NameSnapshot = menu.NameVi,
                ImageUrlSnapshot = menu.ImageUrl,
                UnitPrice = menu.Price,
                Quantity = line.Quantity,
                Subtotal = lineSubtotal,
                Notes = line.Notes,
            });
        }

        var deliveryFee = _settings.DefaultDeliveryFee;
        var orderId = Guid.NewGuid();
        var charge = await _paymentClient.ChargeMealOrderAsync(new ChargeMealOrderRequest
        {
            UserId = userId,
            OrderId = orderId,
            Amount = subtotal + deliveryFee,
            VoucherId = dto.VoucherId,
            IsAiInitiated = dto.IsAiInitiated,
        }, cancellationToken);

        if (!charge.Success)
            throw new BadRequestException(charge.FailureReason ?? "Payment failed.");

        var discount = charge.DiscountAmount;
        var total = subtotal + deliveryFee - discount;
        var now = DateTimeOffset.UtcNow;

        var order = new Domain.Models.Order
        {
            Id = orderId,
            UserId = userId,
            PartnerId = dto.PartnerId,
            OrderCode = OrderCodeGenerator.Generate(),
            Status = OrderStatus.Confirmed,
            SubtotalAmount = subtotal,
            DeliveryFee = deliveryFee,
            DiscountAmount = discount,
            TotalAmount = total,
            Currency = "VND",
            PaymentTransactionId = charge.TransactionId,
            PaymentStatus = PaymentStatus.Paid,
            VoucherId = dto.VoucherId,
            DeliveryAddress = dto.DeliveryAddress,
            DeliveryLat = dto.DeliveryLat,
            DeliveryLng = dto.DeliveryLng,
            RecipientName = dto.RecipientName,
            RecipientPhone = dto.RecipientPhone,
            Notes = dto.Notes,
            IsAiInitiated = dto.IsAiInitiated,
            AIReasoningSnapshotJson = dto.AIReasoningSnapshotJson,
            PlacedAt = now,
            ConfirmedAt = now,
            Items = orderItems,
        };

        foreach (var item in orderItems)
            item.OrderId = order.Id;

        await using var tx = await _db.Database.BeginTransactionAsync(cancellationToken);
        _db.Orders.Add(order);
        _db.OrderStatusHistories.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = OrderStatus.Pending,
            ToStatus = OrderStatus.Confirmed,
            ChangedBy = "system",
            Note = "Payment succeeded",
        });

        if (!string.IsNullOrWhiteSpace(dto.ClientRequestKey))
        {
            _db.OrderIdempotencyKeys.Add(new OrderIdempotencyKey
            {
                UserId = userId,
                ClientRequestKey = dto.ClientRequestKey!,
                OrderId = order.Id,
            });
        }

        await _db.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        await _notificationClient.SendOrderStatusAsync(
            userId,
            "Đơn hàng đã đặt",
            $"Đơn {order.OrderCode} đã được xác nhận.",
            order.Id,
            cancellationToken);

        _logger.LogInformation(
            "OrderPlaced {Event}: {OrderId} user={UserId} partner={PartnerId} total={Total}",
            nameof(OrderPlacedEvent),
            order.Id,
            userId,
            order.PartnerId,
            order.TotalAmount);
        return order.ToDto();
    }

    public async Task<OrderDetailDto> GetOrderDetailForUserAsync(
        Guid userId,
        Guid orderId,
        CancellationToken cancellationToken = default)
    {
        var order = await LoadOrderAsync(orderId, cancellationToken);
        if (order.UserId != userId)
            throw new ForbiddenException("You do not have access to this order.");

        var tracking = await _deliveryTrackingService.GetTrackingAsync(orderId, cancellationToken);
        var dto = order.ToDto();
        return new OrderDetailDto
        {
            Id = dto.Id,
            UserId = dto.UserId,
            PartnerId = dto.PartnerId,
            OrderCode = dto.OrderCode,
            Status = dto.Status,
            SubtotalAmount = dto.SubtotalAmount,
            DeliveryFee = dto.DeliveryFee,
            DiscountAmount = dto.DiscountAmount,
            TotalAmount = dto.TotalAmount,
            Currency = dto.Currency,
            PaymentStatus = dto.PaymentStatus,
            DeliveryAddress = dto.DeliveryAddress,
            DeliveryLat = dto.DeliveryLat,
            DeliveryLng = dto.DeliveryLng,
            RecipientName = dto.RecipientName,
            RecipientPhone = dto.RecipientPhone,
            Notes = dto.Notes,
            IsAiInitiated = dto.IsAiInitiated,
            PlacedAt = dto.PlacedAt,
            CompletedAt = dto.CompletedAt,
            Items = dto.Items,
            Tracking = tracking,
        };
    }

    public async Task<(IReadOnlyList<OrderDto> Items, PaginationMetadata Pagination)> ListUserOrdersAsync(
        Guid userId,
        OrderListRequest request,
        CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, request.PageNumber);
        var size = Math.Clamp(request.PageSize, 1, 100);
        var query = _db.Orders.AsNoTracking().Include(o => o.Items).Where(o => o.UserId == userId);
        if (request.Status.HasValue)
            query = query.Where(o => o.Status == request.Status.Value);

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderByDescending(o => o.PlacedAt)
            .Skip((page - 1) * size).Take(size).ToListAsync(cancellationToken);
        return (items.Select(o => o.ToDto()).ToList(), new PaginationMetadata(page, size, total));
    }

    public async Task<(IReadOnlyList<OrderDto> Items, PaginationMetadata Pagination)> ListPartnerOrdersAsync(
        Guid partnerOwnerUserId,
        Guid partnerId,
        OrderListRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsurePartnerOwnerAsync(partnerOwnerUserId, partnerId, cancellationToken);
        var page = Math.Max(1, request.PageNumber);
        var size = Math.Clamp(request.PageSize, 1, 100);
        var query = _db.Orders.AsNoTracking().Include(o => o.Items).Where(o => o.PartnerId == partnerId);
        if (request.Status.HasValue)
            query = query.Where(o => o.Status == request.Status.Value);

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderByDescending(o => o.PlacedAt)
            .Skip((page - 1) * size).Take(size).ToListAsync(cancellationToken);
        return (items.Select(o => o.ToDto()).ToList(), new PaginationMetadata(page, size, total));
    }

    public async Task<OrderDto> PartnerUpdateStatusAsync(
        Guid partnerOwnerUserId,
        Guid partnerId,
        Guid orderId,
        UpdateOrderStatusDto dto,
        CancellationToken cancellationToken = default)
    {
        await EnsurePartnerOwnerAsync(partnerOwnerUserId, partnerId, cancellationToken);
        var order = await LoadOrderAsync(orderId, cancellationToken);
        if (order.PartnerId != partnerId)
            throw new NotFoundException(nameof(Domain.Models.Order), orderId);
        if (!OrderStatusStateMachine.CanPartnerTransition(order.Status, dto.Status))
            throw new BadRequestException($"Invalid partner status transition {order.Status} -> {dto.Status}.");

        await ApplyStatusChangeAsync(order, dto.Status, "partner", dto.Note, cancellationToken);

        if (dto.Status == OrderStatus.ReadyForPickup)
            await _deliveryTrackingService.BookDeliveryAsync(order.Id, cancellationToken);

        return order.ToDto();
    }

    public async Task<OrderDto> CancelOrderAsync(
        Guid userId,
        Guid orderId,
        CancelOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        var order = await LoadOrderAsync(orderId, cancellationToken);
        if (order.UserId != userId)
            throw new ForbiddenException("You do not own this order.");
        if (!OrderStatusStateMachine.CanCancel(order.Status))
            throw new BadRequestException("Order cannot be cancelled in its current status.");

        await ApplyStatusChangeAsync(order, OrderStatus.Cancelled, "user", dto.Reason, cancellationToken);
        order.CancelledAt = DateTimeOffset.UtcNow;
        order.CancellationReason = dto.Reason;
        order.CancelledBy = CancelledByType.User;

        var refund = await _paymentClient.RefundMealOrderAsync(new RefundMealOrderRequest
        {
            UserId = userId,
            OrderId = order.Id,
            OriginalTransactionId = order.PaymentTransactionId,
            Amount = order.TotalAmount,
            Currency = order.Currency,
        }, cancellationToken);

        if (refund.Success)
        {
            order.PaymentStatus = PaymentStatus.Refunded;
            await ApplyStatusChangeAsync(order, OrderStatus.Refunded, "system", "Payment refunded", cancellationToken);
        }

        await _db.SaveChangesAsync(cancellationToken);
        return order.ToDto();
    }

    public async Task<OrderDto> ApplySystemStatusAsync(
        Guid orderId,
        OrderStatus toStatus,
        string changedBy,
        string? note = null,
        CancellationToken cancellationToken = default)
    {
        var order = await LoadOrderAsync(orderId, cancellationToken);
        if (!OrderStatusStateMachine.CanSystemTransition(order.Status, toStatus))
            throw new BadRequestException($"Invalid system status transition {order.Status} -> {toStatus}.");

        await ApplyStatusChangeAsync(order, toStatus, changedBy, note, cancellationToken);
        return order.ToDto();
    }

    private async Task ApplyStatusChangeAsync(
        Domain.Models.Order order,
        OrderStatus toStatus,
        string changedBy,
        string? note,
        CancellationToken cancellationToken)
    {
        if (order.Status == toStatus)
            return;
        if (!OrderStatusStateMachine.CanTransition(order.Status, toStatus))
            throw new BadRequestException($"Invalid status transition {order.Status} -> {toStatus}.");

        var from = order.Status;
        order.Status = toStatus;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        if (toStatus == OrderStatus.Completed)
            order.CompletedAt = DateTimeOffset.UtcNow;

        _db.OrderStatusHistories.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = from,
            ToStatus = toStatus,
            ChangedBy = changedBy,
            Note = note,
        });

        await _db.SaveChangesAsync(cancellationToken);

        await _notificationClient.SendOrderStatusAsync(
            order.UserId,
            "Cập nhật đơn hàng",
            $"Đơn {order.OrderCode}: {from} → {toStatus}",
            order.Id,
            cancellationToken);

        _logger.LogInformation(
            "OrderStatusChanged {Event}: {OrderId} {FromStatus} -> {ToStatus} by={ChangedBy}",
            nameof(OrderStatusChangedEvent),
            order.Id,
            from,
            toStatus,
            changedBy);

        if (toStatus == OrderStatus.Completed)
        {
            await _commissionService.CreateFoodDeliveryCommissionAsync(order.Id, cancellationToken);
            await PublishOrderCompletedAsync(order, cancellationToken);
        }
    }

    private async Task PublishOrderCompletedAsync(Domain.Models.Order order, CancellationToken cancellationToken)
    {
        var partner = await _marketplaceClient.GetPartnerAsync(order.PartnerId, cancellationToken);
        _ = partner;

        var validated = await _marketplaceClient.ValidateOrderItemsAsync(new ValidateOrderItemsRequest
        {
            PartnerId = order.PartnerId,
            FoodMenuItemIds = order.Items.Select(i => i.FoodMenuItemId).ToList(),
        }, cancellationToken);

        var nutritionById = validated.Items.ToDictionary(x => x.FoodMenuItemId);
        var evt = new OrderCompletedEvent
        {
            OrderId = order.Id,
            UserId = order.UserId,
            CompletedAt = order.CompletedAt ?? DateTimeOffset.UtcNow,
            Items = order.Items.Select(i =>
            {
                nutritionById.TryGetValue(i.FoodMenuItemId, out var menu);
                return new OrderCompletedLineItem
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
        };

        await _nutritionEventClient.PublishOrderCompletedAsync(evt, cancellationToken);
    }

    private async Task<Domain.Models.Order> LoadOrderAsync(Guid orderId, CancellationToken cancellationToken)
    {
        var order = await _db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        return order ?? throw new NotFoundException(nameof(Domain.Models.Order), orderId);
    }

    private async Task EnsurePartnerOwnerAsync(Guid ownerUserId, Guid partnerId, CancellationToken cancellationToken)
    {
        var partner = await _marketplaceClient.GetPartnerAsync(partnerId, cancellationToken);
        if (partner == null || partner.OwnerUserId != ownerUserId)
            throw new ForbiddenException("You do not own this partner profile.");
    }
}
