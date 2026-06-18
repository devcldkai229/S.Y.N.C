using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using Payment.Application.Common;
using Payment.Application.Services;

namespace Payment.API.Controllers;

/// <summary>
/// DEV-ONLY: helpers for testing the subscription flow without real PayOS transactions.
/// Every action returns 404 outside the Development environment.
/// Remove or lock this controller before deploying to production.
/// </summary>
[ApiController]
[Route("api/v1/payments/dev")]
public class PaymentDevController : ControllerBase
{
    private readonly IPayosPaymentService _payosService;
    private readonly IWebHostEnvironment _env;

    public PaymentDevController(IPayosPaymentService payosService, IWebHostEnvironment env)
    {
        _payosService = payosService;
        _env          = env;
    }

    /// <summary>
    /// Simulate a successful PayOS payment for an existing pending transaction.
    /// Skips signature verification and directly activates the subscription.
    ///
    /// Flow: create-link → copy orderCode → POST /api/v1/payments/dev/confirm/{orderCode}
    /// </summary>
    [HttpPost("confirm/{orderCode:long}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Confirm(long orderCode, CancellationToken cancellationToken)
    {
        if (!_env.IsDevelopment())
            return NotFound();

        var result = await _payosService.ActivateForDevAsync(orderCode, cancellationToken);

        return Ok(ApiResponse<object>.SuccessResponse(
            new { result.Outcome, result.OrderCode, result.Message },
            result.Message));
    }
}
