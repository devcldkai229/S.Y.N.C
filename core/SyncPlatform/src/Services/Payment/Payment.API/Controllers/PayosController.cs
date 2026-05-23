using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/payos")]
public class PayosController : ControllerBase
{
    private readonly IPayosPaymentService _payosService;
    private readonly ICurrentUserContext _currentUser;

    public PayosController(IPayosPaymentService payosService, ICurrentUserContext currentUser)
    {
        _payosService = payosService;
        _currentUser = currentUser;
    }

    /// <summary>
    /// POST /api/v1/payments/payos/create-link
    /// Authenticated user requests a PayOS checkout URL + QR code for a subscription plan.
    /// </summary>
    [HttpPost("create-link")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<CreatePaymentLinkResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status502BadGateway)]
    public async Task<ActionResult<ApiResponse<CreatePaymentLinkResponse>>> CreateLink(
        [FromBody] CreatePaymentLinkRequest request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _payosService.CreatePaymentLinkAsync(userId, request, cancellationToken);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<CreatePaymentLinkResponse>.SuccessResponse(result, "Payment link created."));
    }

    /// <summary>
    /// POST /api/v1/payments/payos/webhook
    /// PayOS callback. Signature verified server-side — must remain anonymous.
    /// </summary>
    [HttpPost("webhook")]
    [AllowAnonymous]
    [Consumes("application/json")]
    [ProducesResponseType(typeof(ApiResponse<PayosWebhookProcessResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<PayosWebhookProcessResult>>> Webhook(CancellationToken cancellationToken)
    {
        string rawBody;
        Request.EnableBuffering();
        Request.Body.Position = 0;
        using (var reader = new StreamReader(Request.Body, leaveOpen: true))
        {
            rawBody = await reader.ReadToEndAsync(cancellationToken);
        }

        if (string.IsNullOrWhiteSpace(rawBody))
            throw new BadRequestException("Webhook body is empty.");

        var result = await _payosService.ProcessWebhookAsync(rawBody, cancellationToken);

        return Ok(ApiResponse<PayosWebhookProcessResult>.SuccessResponse(result, result.Message));
    }
}
