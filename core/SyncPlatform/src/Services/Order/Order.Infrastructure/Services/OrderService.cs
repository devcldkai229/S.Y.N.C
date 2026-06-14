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
using Order.Application.Ports;
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
    private readonly ICartStore _cartStore;
    private readonly IDeliveryAddressStore _deliveryAddressStore;
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
        ICartStore cartStore,
        IDeliveryAddressStore deliveryAddressStore,
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
        _cartStore = cartStore;
        _deliveryAddressStore = deliveryAddressStore;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<PlaceOrderResultDto> PlaceOrderAsync(
        Guid userId,
        PlaceOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        await HydrateFromCheckoutSessionAsync(userId, dto, cancellationToken);

        if (dto.Items.Count == 0)
            throw new BadRequestException("Giỏ hàng trống.");

        var idempotencyKey = dto.IdempotencyKey ?? dto.ClientRequestKey;
        if (!string.IsNullOrWhiteSpace(idempotencyKey))
        {
            var existing = await _db.OrderIdempotencyKeys
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.UserId == userId && x.ClientRequestKey == idempotencyKey,
                    cancellationToken);
            if (existing != null)
            {
                var existingOrder = await LoadOrderAsync(existing.OrderId, cancellationToken);
                return new PlaceOrderResultDto
                {
                    Order = existingOrder.ToDto(),
                    RequiresExternalPayment = existingOrder.PaymentStatus == PaymentStatus.Unpaid
                        && existingOrder.Status == OrderStatus.Pending,
                };
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
        var preDiscountTotal = subtotal + deliveryFee;
        decimal discount = 0;
        Guid? voucherCampaignId = dto.VoucherId;
        string? voucherCode = dto.VoucherCode;

        if (!string.IsNullOrWhiteSpace(voucherCode))
        {
            var voucher = await _paymentClient.ValidateVoucherAsync(new ValidateVoucherRequest
            {
                UserId = userId,
                Code = voucherCode,
                OrderAmount = preDiscountTotal,
                PartnerId = dto.PartnerId,
            }, cancellationToken);

            if (!voucher.Valid)
                throw new BadRequestException(voucher.Message ?? "Voucher không hợp lệ.");

            discount = voucher.DiscountAmount;
            voucherCampaignId = voucher.CampaignId;
            voucherCode = voucherCode.Trim().ToUpperInvariant();
        }

        var total = preDiscountTotal - discount;
        var orderId = Guid.NewGuid();
        var orderCode = OrderCodeGenerator.Generate();
        var now = DateTimeOffset.UtcNow;

        Guid? paymentTransactionId = null;
        string? payUrl = null;
        string? deeplink = null;
        string? checkoutUrl = null;
        string? qrCode = null;
        long? payOsOrderCode = null;
        var requiresExternalPayment = false;
        OrderStatus orderStatus;
        PaymentStatus paymentStatus;

        switch (dto.PaymentMethod)
        {
            case CheckoutPaymentMethod.Wallet:
            {
                var charge = await _paymentClient.ChargeMealOrderAsync(new ChargeMealOrderRequest
                {
                    UserId = userId,
                    OrderId = orderId,
                    Amount = total,
                    IsAiInitiated = dto.IsAiInitiated,
                }, cancellationToken);

                if (!charge.Success)
                {
                    if (charge.InsufficientBalance)
                        throw new PaymentRequiredException(charge.FailureReason ?? "Số dư ví không đủ.");
                    throw new BadRequestException(charge.FailureReason ?? "Thanh toán ví thất bại.");
                }

                paymentTransactionId = charge.TransactionId;
                orderStatus = OrderStatus.Confirmed;
                paymentStatus = PaymentStatus.Paid;
                break;
            }
            case CheckoutPaymentMethod.COD:
            {
                var cod = await _paymentClient.CreateCodTransactionAsync(new CreateCodPaymentRequest
                {
                    UserId = userId,
                    OrderId = orderId,
                    Amount = total,
                }, cancellationToken);

                if (!cod.Success)
                    throw new BadRequestException("Không tạo được giao dịch COD.");

                paymentTransactionId = cod.TransactionId;
                orderStatus = OrderStatus.Confirmed;
                paymentStatus = PaymentStatus.Unpaid;
                break;
            }
            case CheckoutPaymentMethod.VietQR:
            {
                var vietQr = await _paymentClient.CreateVietQrPaymentAsync(new CreateVietQrPaymentRequest
                {
                    UserId = userId,
                    OrderId = orderId,
                    OrderCode = orderCode,
                    Amount = total,
                }, cancellationToken);

                if (!vietQr.Success)
                    throw new BadRequestException(vietQr.FailureReason ?? "Không tạo được thanh toán VietQR.");

                paymentTransactionId = vietQr.TransactionId;
                payUrl = vietQr.CheckoutUrl;
                checkoutUrl = vietQr.CheckoutUrl;
                qrCode = vietQr.QrCode;
                payOsOrderCode = vietQr.PayOsOrderCode;
                requiresExternalPayment = true;
                orderStatus = OrderStatus.Pending;
                paymentStatus = PaymentStatus.Unpaid;
                break;
            }
            default:
                throw new BadRequestException("Phương thức thanh toán không hợp lệ.");
        }

        var order = new Domain.Models.Order
        {
            Id = orderId,
            UserId = userId,
            PartnerId = dto.PartnerId,
            OrderCode = orderCode,
            Status = orderStatus,
            SubtotalAmount = subtotal,
            DeliveryFee = deliveryFee,
            DiscountAmount = discount,
            TotalAmount = total,
            Currency = "VND",
            PaymentTransactionId = paymentTransactionId,
            PaymentStatus = paymentStatus,
            VoucherId = voucherCampaignId,
            VoucherCode = voucherCode,
            DeliveryAddress = dto.DeliveryAddress,
            DeliveryLat = dto.DeliveryLat,
            DeliveryLng = dto.DeliveryLng,
            RecipientName = dto.RecipientName,
            RecipientPhone = dto.RecipientPhone,
            Notes = dto.Notes,
            IsAiInitiated = dto.IsAiInitiated,
            AIReasoningSnapshotJson = dto.AIReasoningSnapshotJson,
            PlacedAt = now,
            ConfirmedAt = orderStatus == OrderStatus.Confirmed ? now : null,
            Items = orderItems,
        };

        foreach (var item in orderItems)
            item.OrderId = order.Id;

        var strategy = _db.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(
            (object?)null,
            async (_, _, ct) =>
            {
                await using var tx = await _db.Database.BeginTransactionAsync(ct);
                _db.Orders.Add(order);
                _db.OrderStatusHistories.Add(new OrderStatusHistory
                {
                    OrderId = order.Id,
                    FromStatus = OrderStatus.Pending,
                    ToStatus = orderStatus,
                    ChangedBy = "system",
                    Note = dto.PaymentMethod.ToString(),
                });

                if (!string.IsNullOrWhiteSpace(idempotencyKey))
                {
                    _db.OrderIdempotencyKeys.Add(new OrderIdempotencyKey
                    {
                        UserId = userId,
                        ClientRequestKey = idempotencyKey!,
                        OrderId = order.Id,
                    });
                }

                await _db.SaveChangesAsync(ct);
                await tx.CommitAsync(ct);
                return true;
            },
            verifySucceeded: null,
            cancellationToken);

        if (orderStatus == OrderStatus.Confirmed)
        {
            await FinalizeSuccessfulOrderAsync(userId, order, voucherCode, clearCart: true, cancellationToken);
        }

        _logger.LogInformation(
            "OrderPlaced {Event}: {OrderId} user={UserId} partner={PartnerId} total={Total} method={Method}",
            nameof(OrderPlacedEvent),
            order.Id,
            userId,
            order.PartnerId,
            order.TotalAmount,
            dto.PaymentMethod);

        return new PlaceOrderResultDto
        {
            Order = order.ToDto(),
            PayUrl = payUrl,
            Deeplink = deeplink,
            CheckoutUrl = checkoutUrl,
            QrCode = qrCode,
            PayOsOrderCode = payOsOrderCode,
            RequiresExternalPayment = requiresExternalPayment,
        };
    }

    public async Task<OrderDto> ConfirmOrderPaymentAsync(
        Guid orderId,
        Guid transactionId,
        CancellationToken cancellationToken = default)
    {
        var order = await LoadOrderAsync(orderId, cancellationToken);
        if (order.PaymentStatus == PaymentStatus.Paid && order.Status == OrderStatus.Confirmed)
            return order.ToDto();

        order.PaymentStatus = PaymentStatus.Paid;
        order.PaymentTransactionId = transactionId;
        order.Status = OrderStatus.Confirmed;
        order.ConfirmedAt = DateTimeOffset.UtcNow;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        _db.OrderStatusHistories.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = OrderStatus.Pending,
            ToStatus = OrderStatus.Confirmed,
            ChangedBy = "payos-webhook",
            Note = "VietQR payment succeeded",
        });

        await _db.SaveChangesAsync(cancellationToken);
        await FinalizeSuccessfulOrderAsync(order.UserId, order, order.VoucherCode, clearCart: true, cancellationToken);
        return order.ToDto();
    }

    public async Task<int> GetActiveOrderCountAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var terminal = new[]
        {
            OrderStatus.Delivered,
            OrderStatus.Completed,
            OrderStatus.Cancelled,
            OrderStatus.Refunded,
        };

        return await _db.Orders.AsNoTracking()
            .CountAsync(o => o.UserId == userId && !terminal.Contains(o.Status), cancellationToken);
    }

    private async Task FinalizeSuccessfulOrderAsync(
        Guid userId,
        Domain.Models.Order order,
        string? voucherCode,
        bool clearCart,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(voucherCode))
        {
            await _paymentClient.MarkVoucherUsedAsync(new MarkVoucherUsedRequest
            {
                UserId = userId,
                Code = voucherCode,
                OrderId = order.Id,
            }, cancellationToken);
        }

        await _notificationClient.SendOrderStatusAsync(
            userId,
            "Đặt hàng thành công",
            $"Đơn {order.OrderCode} đã được xác nhận.",
            order.Id,
            cancellationToken);

        if (clearCart)
            await _cartStore.DeleteAsync(userId, cancellationToken);

        try
        {
            await _deliveryTrackingService.KickoffDeliveryAsync(order.Id, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Delivery kickoff failed for order {OrderId}", order.Id);
        }
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

    private async Task HydrateFromCheckoutSessionAsync(
        Guid userId,
        PlaceOrderDto dto,
        CancellationToken cancellationToken)
    {
        if (dto.Items.Count == 0 || dto.PartnerId == Guid.Empty)
        {
            var cart = await _cartStore.GetAsync(userId, cancellationToken);
            if (cart is { Items.Count: > 0, PartnerId: not null })
            {
                dto.PartnerId = cart.PartnerId.Value;
                dto.Items = cart.Items.Select(i => new PlaceOrderItemDto
                {
                    FoodMenuItemId = i.FoodMenuItemId,
                    Quantity = i.Quantity,
                    Notes = i.Notes,
                }).ToList();
            }
        }

        if (string.IsNullOrWhiteSpace(dto.DeliveryAddress) ||
            !dto.DeliveryLat.HasValue ||
            !dto.DeliveryLng.HasValue)
        {
            var address = await _deliveryAddressStore.GetAsync(userId, cancellationToken);
            if (address != null)
            {
                dto.DeliveryAddress ??= address.Label;
                dto.DeliveryLat ??= (decimal)address.Lat;
                dto.DeliveryLng ??= (decimal)address.Lng;
            }
        }
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
