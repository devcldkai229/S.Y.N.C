using Order.Application.Common;
using Order.Application.DTOs;
using Order.Domain.Enums;

namespace Order.Application.Services;

public interface IOrderService
{
    Task<OrderDto> PlaceOrderAsync(Guid userId, PlaceOrderDto dto, CancellationToken cancellationToken = default);

    Task<OrderDetailDto> GetOrderDetailForUserAsync(Guid userId, Guid orderId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<OrderDto> Items, PaginationMetadata Pagination)> ListUserOrdersAsync(
        Guid userId,
        OrderListRequest request,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<OrderDto> Items, PaginationMetadata Pagination)> ListPartnerOrdersAsync(
        Guid partnerOwnerUserId,
        Guid partnerId,
        OrderListRequest request,
        CancellationToken cancellationToken = default);

    Task<OrderDto> PartnerUpdateStatusAsync(
        Guid partnerOwnerUserId,
        Guid partnerId,
        Guid orderId,
        UpdateOrderStatusDto dto,
        CancellationToken cancellationToken = default);

    Task<OrderDto> CancelOrderAsync(
        Guid userId,
        Guid orderId,
        CancelOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<OrderDto> ApplySystemStatusAsync(
        Guid orderId,
        OrderStatus toStatus,
        string changedBy,
        string? note = null,
        CancellationToken cancellationToken = default);
}
