using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

/// <summary>Order placement & tracking for SYNC AI (internal API key).</summary>
[ApiController]
[Route("api/internal/orders")]
[AllowAnonymous]
public class InternalOrderAiController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly IDeliveryTrackingService _trackingService;
    private readonly ICheckoutSessionService _checkout;

    public InternalOrderAiController(
        IOrderService orderService,
        IDeliveryTrackingService trackingService,
        ICheckoutSessionService checkout)
    {
        _orderService = orderService;
        _trackingService = trackingService;
        _checkout = checkout;
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<PlaceOrderResultDto>>> PlaceOrder(
        [FromBody] InternalPlaceOrderRequestDto dto,
        CancellationToken cancellationToken)
    {
        dto.IsAiInitiated = true;
        var result = await _orderService.PlaceOrderAsync(dto.UserId, dto, cancellationToken);
        return Ok(ApiResponse<PlaceOrderResultDto>.SuccessResponse(result, "Order placed successfully."));
    }

    [HttpPost("quote")]
    public async Task<ActionResult<ApiResponse<QuoteOrderResultDto>>> Quote(
        [FromBody] QuoteOrderRequestDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.QuoteOrderAsync(dto, cancellationToken);
        return Ok(ApiResponse<QuoteOrderResultDto>.SuccessResponse(result, "Quote calculated."));
    }

    [HttpGet("{orderId:guid}")]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> GetOrder(
        Guid orderId,
        [FromQuery] Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _orderService.GetOrderDetailForUserAsync(userId, orderId, cancellationToken);
        return Ok(ApiResponse<OrderDetailDto>.SuccessResponse(result, "Order retrieved."));
    }

    [HttpGet("users/{userId:guid}/delivery-address")]
    public async Task<ActionResult<ApiResponse<DeliveryAddressDto?>>> GetDeliveryAddress(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var address = await _checkout.GetDeliveryAddressAsync(userId, cancellationToken);
        return Ok(ApiResponse<DeliveryAddressDto?>.SuccessResponse(
            address, address == null ? "No delivery address saved." : "Delivery address retrieved."));
    }

    [HttpGet("{orderId:guid}/tracking")]
    public async Task<ActionResult<ApiResponse<DeliveryTrackingDto?>>> GetTracking(
        Guid orderId,
        [FromQuery] Guid userId,
        CancellationToken cancellationToken)
    {
        _ = await _orderService.GetOrderDetailForUserAsync(userId, orderId, cancellationToken);
        var tracking = await _trackingService.GetTrackingAsync(orderId, cancellationToken);
        return Ok(ApiResponse<DeliveryTrackingDto?>.SuccessResponse(tracking, "Tracking retrieved."));
    }

    [HttpPost("reorder")]
    public async Task<ActionResult<ApiResponse<PlaceOrderResultDto>>> Reorder(
        [FromBody] InternalReorderRequestDto dto,
        CancellationToken cancellationToken)
    {
        var previous = await _orderService.GetOrderDetailForUserAsync(
            dto.UserId, dto.PreviousOrderId, cancellationToken);
        var placeDto = new PlaceOrderDto
        {
            PartnerId = previous.PartnerId,
            Items = previous.Items.Select(i => new PlaceOrderItemDto
            {
                FoodMenuItemId = i.FoodMenuItemId,
                Quantity = i.Quantity,
            }).ToList(),
            DeliveryAddress = previous.DeliveryAddress,
            RecipientPhone = previous.RecipientPhone,
            RecipientName = previous.RecipientName,
            PaymentMethod = CheckoutPaymentMethod.Deferred,
            ClientRequestKey = dto.IdempotencyKey,
            IdempotencyKey = dto.IdempotencyKey,
            IsAiInitiated = true,
            AIReasoningSnapshotJson = dto.AIReasoningSnapshotJson,
        };
        var result = await _orderService.PlaceOrderAsync(dto.UserId, placeDto, cancellationToken);
        return Ok(ApiResponse<PlaceOrderResultDto>.SuccessResponse(result, "Reorder placed."));
    }
}

/// <summary>userId + <see cref="PlaceOrderDto"/> fields for AI-initiated checkout.</summary>
public class InternalPlaceOrderRequestDto : PlaceOrderDto
{
    public Guid UserId { get; set; }
}

public class InternalReorderRequestDto
{
    public Guid UserId { get; set; }
    public Guid PreviousOrderId { get; set; }
    public string IdempotencyKey { get; set; } = string.Empty;
    public string? AIReasoningSnapshotJson { get; set; }
}
