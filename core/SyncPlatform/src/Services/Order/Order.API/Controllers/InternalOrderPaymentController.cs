using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/orders")]
public class InternalOrderPaymentController : ControllerBase
{
    private readonly IOrderService _orderService;

    public InternalOrderPaymentController(IOrderService orderService) => _orderService = orderService;

    [HttpPost("{orderId:guid}/confirm-payment")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> ConfirmPayment(
        Guid orderId,
        [FromBody] ConfirmOrderPaymentDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.ConfirmOrderPaymentAsync(orderId, dto.TransactionId, cancellationToken);
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Order payment confirmed."));
    }
}

public class ConfirmOrderPaymentDto
{
    public Guid TransactionId { get; set; }
}
