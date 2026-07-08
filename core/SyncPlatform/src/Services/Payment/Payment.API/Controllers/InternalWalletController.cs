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

    [HttpGet("{userId:guid}/balance")]
    public async Task<ActionResult<ApiResponse<WalletBalanceDto>>> GetBalance(
        Guid userId,
        [FromServices] IOrderPaymentService orderPaymentService,
        CancellationToken cancellationToken)
    {
        var balance = await orderPaymentService.GetWalletBalanceAsync(userId, cancellationToken);
        return Ok(ApiResponse<WalletBalanceDto>.SuccessResponse(balance, "Wallet balance retrieved."));
    }

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

    [HttpPost("topup")]
    public ActionResult<ApiResponse<object>> TopupWallet([FromBody] InternalWalletTopupRequestDto request)
    {
        return Ok(ApiResponse<object>.SuccessResponse(new
        {
            request.UserId,
            request.Amount,
            request.Method,
            status = "requires_payment_confirmation",
            message = "Top-up must be confirmed via payment gateway.",
        }, "Top-up initiated."));
    }
}

public class InternalWalletTopupRequestDto
{
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = "VietQR";
}
