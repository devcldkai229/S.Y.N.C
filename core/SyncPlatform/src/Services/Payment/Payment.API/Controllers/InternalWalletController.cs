using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/wallet")]
public class InternalWalletController : ControllerBase
{
    private readonly IInternalWalletService _service;

    public InternalWalletController(IInternalWalletService service) => _service = service;

    [HttpPost("charge-meal-order")]
    public async Task<ActionResult<ApiResponse<ChargeMealOrderResponseDto>>> ChargeMealOrder(
        [FromBody] ChargeMealOrderRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.ChargeMealOrderAsync(request, cancellationToken);
        return Ok(ApiResponse<ChargeMealOrderResponseDto>.SuccessResponse(result, "Charge processed."));
    }

    [HttpPost("refund-meal-order")]
    public async Task<ActionResult<ApiResponse<RefundMealOrderResponseDto>>> RefundMealOrder(
        [FromBody] RefundMealOrderRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.RefundMealOrderAsync(request, cancellationToken);
        return Ok(ApiResponse<RefundMealOrderResponseDto>.SuccessResponse(result, "Refund processed."));
    }
}
