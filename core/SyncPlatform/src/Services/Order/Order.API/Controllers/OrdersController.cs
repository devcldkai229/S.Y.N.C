using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/orders")]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly IDeliveryTrackingService _trackingService;
    private readonly ICurrentUserContext _currentUser;

    public OrdersController(
        IOrderService orderService,
        IDeliveryTrackingService trackingService,
        ICurrentUserContext currentUser)
    {
        _orderService = orderService;
        _trackingService = trackingService;
        _currentUser = currentUser;
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<OrderDto>>> PlaceOrder(
        [FromBody] PlaceOrderDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.PlaceOrderAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<OrderDto>.SuccessResponse(result, "Order placed successfully."));
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<OrderDto>>>> List(
        [FromQuery] OrderListRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _orderService.ListUserOrdersAsync(_currentUser.RequireUserId(), request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<OrderDto>>.SuccessPagedResponse(items, pagination, "Orders retrieved."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _orderService.GetOrderDetailForUserAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<OrderDetailDto>.SuccessResponse(result, "Order retrieved."));
    }

    [HttpGet("{id:guid}/tracking")]
    public async Task<ActionResult<ApiResponse<DeliveryTrackingDto?>>> GetTracking(Guid id, CancellationToken cancellationToken)
    {
        _ = await _orderService.GetOrderDetailForUserAsync(_currentUser.RequireUserId(), id, cancellationToken);
        var tracking = await _trackingService.GetTrackingAsync(id, cancellationToken);
        return Ok(ApiResponse<DeliveryTrackingDto?>.SuccessResponse(tracking, "Tracking retrieved."));
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> Cancel(
        Guid id,
        [FromBody] CancelOrderDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.CancelOrderAsync(_currentUser.RequireUserId(), id, dto, cancellationToken);
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Order cancelled."));
    }
}
