using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/orders")]
public class InternalOrderVerificationController : ControllerBase
{
    private readonly IInternalOrderVerificationService _service;

    public InternalOrderVerificationController(IInternalOrderVerificationService service)
    {
        _service = service;
    }

    [HttpGet("verify-purchase")]
    public async Task<ActionResult<ApiResponse<OrderVerificationResultDto>>> VerifyPurchase(
        [FromQuery] Guid userId,
        [FromQuery] string targetType,
        [FromQuery] Guid targetId,
        [FromQuery] Guid? orderId,
        CancellationToken cancellationToken)
    {
        var result = await _service.VerifyPurchaseAsync(userId, targetType, targetId, orderId, cancellationToken);
        return Ok(ApiResponse<OrderVerificationResultDto>.SuccessResponse(result, "Purchase verification completed."));
    }
}
