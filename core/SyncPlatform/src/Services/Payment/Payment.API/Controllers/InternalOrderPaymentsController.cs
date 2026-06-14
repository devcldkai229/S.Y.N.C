using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/order-payments")]
public class InternalOrderPaymentsController : ControllerBase
{
    private readonly IOrderPaymentService _orderPaymentService;

    public InternalOrderPaymentsController(IOrderPaymentService orderPaymentService) =>
        _orderPaymentService = orderPaymentService;

    [HttpPost("charge-wallet")]
    public async Task<ActionResult<ApiResponse<ChargeOrderWalletResponseDto>>> ChargeWallet(
        [FromBody] ChargeOrderWalletRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _orderPaymentService.ChargeOrderWalletAsync(request, cancellationToken);
        return Ok(ApiResponse<ChargeOrderWalletResponseDto>.SuccessResponse(result));
    }

    [HttpPost("cod")]
    public async Task<ActionResult<ApiResponse<CreateCodTransactionResponseDto>>> CreateCod(
        [FromBody] CreateCodTransactionRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _orderPaymentService.CreateCodTransactionAsync(request, cancellationToken);
        return Ok(ApiResponse<CreateCodTransactionResponseDto>.SuccessResponse(result));
    }

    [HttpPost("vietqr/create")]
    public async Task<ActionResult<ApiResponse<CreateVietQrPaymentResponseDto>>> CreateVietQr(
        [FromBody] CreateVietQrPaymentRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _orderPaymentService.CreateVietQrPaymentAsync(request, cancellationToken);
        return Ok(ApiResponse<CreateVietQrPaymentResponseDto>.SuccessResponse(result));
    }

    [HttpPost("momo/create")]
    public async Task<ActionResult<ApiResponse<CreateMomoPaymentResponseDto>>> CreateMomo(
        [FromBody] CreateMomoPaymentRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _orderPaymentService.CreateMomoPaymentAsync(request, cancellationToken);
        return Ok(ApiResponse<CreateMomoPaymentResponseDto>.SuccessResponse(result));
    }
}
