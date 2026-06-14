using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.PartnerOnly)]
[Route("api/v1/partners/{partnerId:guid}/orders")]
public class PartnerOrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly ICurrentUserContext _currentUser;

    public PartnerOrdersController(IOrderService orderService, ICurrentUserContext currentUser)
    {
        _orderService = orderService;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<OrderDto>>>> List(
        Guid partnerId,
        [FromQuery] OrderListRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _orderService.ListPartnerOrdersAsync(
            _currentUser.RequireUserId(), partnerId, request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<OrderDto>>.SuccessPagedResponse(items, pagination, "Partner orders retrieved."));
    }

    [HttpPatch("{orderId:guid}/status")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> UpdateStatus(
        Guid partnerId,
        Guid orderId,
        [FromBody] UpdateOrderStatusDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.PartnerUpdateStatusAsync(
            _currentUser.RequireUserId(), partnerId, orderId, dto, cancellationToken);
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Order status updated."));
    }
}
