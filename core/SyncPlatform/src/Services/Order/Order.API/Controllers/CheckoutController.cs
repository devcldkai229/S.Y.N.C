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
[Route("api/v1/checkout")]
public class CheckoutController : ControllerBase
{
    private readonly ICheckoutSessionService _checkout;
    private readonly ICurrentUserContext _currentUser;

    public CheckoutController(ICheckoutSessionService checkout, ICurrentUserContext currentUser)
    {
        _checkout = checkout;
        _currentUser = currentUser;
    }

    [HttpGet("address/search")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<AddressSuggestionDto>>>> SearchAddress(
        [FromQuery] string q,
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        CancellationToken cancellationToken)
    {
        var results = await _checkout.SearchAddressAsync(q, lat, lng, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<AddressSuggestionDto>>.SuccessResponse(results, "Address suggestions retrieved."));
    }

    [HttpGet("address/reverse")]
    public async Task<ActionResult<ApiResponse<ReverseGeocodeResultDto>>> ReverseAddress(
        [FromQuery] double lat,
        [FromQuery] double lng,
        CancellationToken cancellationToken)
    {
        var result = await _checkout.ReverseGeocodeAsync(lat, lng, cancellationToken);
        return Ok(ApiResponse<ReverseGeocodeResultDto>.SuccessResponse(result, "Address resolved."));
    }

    [HttpGet("address/current")]
    public async Task<ActionResult<ApiResponse<DeliveryAddressDto?>>> GetCurrentAddress(CancellationToken cancellationToken)
    {
        var address = await _checkout.GetDeliveryAddressAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<DeliveryAddressDto?>.SuccessResponse(address, address == null ? "No delivery address saved." : "Delivery address retrieved."));
    }

    [HttpPost("address/current")]
    public async Task<ActionResult<ApiResponse<object>>> SaveCurrentAddress(
        [FromBody] SaveDeliveryAddressDto dto,
        CancellationToken cancellationToken)
    {
        await _checkout.SaveDeliveryAddressAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, "Delivery address saved."));
    }

    [HttpGet("fees")]
    public async Task<ActionResult<ApiResponse<CheckoutFeesDto>>> GetFees(CancellationToken cancellationToken)
    {
        var fees = await _checkout.GetCheckoutFeesAsync(cancellationToken);
        return Ok(ApiResponse<CheckoutFeesDto>.SuccessResponse(fees, "Checkout fees retrieved."));
    }

    [HttpGet("cart")]
    public async Task<ActionResult<ApiResponse<CartDto>>> GetCart(CancellationToken cancellationToken)
    {
        var cart = await _checkout.GetCartAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<CartDto>.SuccessResponse(cart, "Cart retrieved."));
    }

    [HttpPost("cart/items")]
    public async Task<ActionResult<ApiResponse<CartDto>>> AddCartItem(
        [FromBody] AddCartItemDto dto,
        CancellationToken cancellationToken)
    {
        var cart = await _checkout.AddCartItemAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<CartDto>.SuccessResponse(cart, "Item added to cart."));
    }

    [HttpPatch("cart/items/{foodMenuItemId:guid}")]
    public async Task<ActionResult<ApiResponse<CartDto>>> UpdateCartItem(
        Guid foodMenuItemId,
        [FromBody] UpdateCartItemQuantityDto dto,
        CancellationToken cancellationToken)
    {
        var cart = await _checkout.UpdateCartItemQuantityAsync(
            _currentUser.RequireUserId(),
            foodMenuItemId,
            dto.Quantity,
            cancellationToken);
        return Ok(ApiResponse<CartDto>.SuccessResponse(cart, "Cart updated."));
    }

    [HttpDelete("cart")]
    public async Task<ActionResult<ApiResponse<object>>> ClearCart(CancellationToken cancellationToken)
    {
        await _checkout.DeleteCartAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, "Cart cleared."));
    }
}
