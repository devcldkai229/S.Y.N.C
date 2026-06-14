using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/vouchers")]
public class InternalVouchersController : ControllerBase
{
    private readonly IVoucherService _voucherService;

    public InternalVouchersController(IVoucherService voucherService) => _voucherService = voucherService;

    [HttpPost("validate")]
    public async Task<ActionResult<ApiResponse<ValidateVoucherResponseDto>>> Validate(
        [FromBody] InternalValidateVoucherRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _voucherService.ValidateInternalAsync(request.UserId, new ValidateVoucherRequestDto
        {
            Code = request.Code,
            OrderAmount = request.OrderAmount,
            PartnerId = request.PartnerId,
        }, cancellationToken);

        return Ok(ApiResponse<ValidateVoucherResponseDto>.SuccessResponse(result));
    }

    [HttpPost("mark-used")]
    public async Task<IActionResult> MarkUsed(
        [FromBody] MarkVoucherUsedRequestDto request,
        CancellationToken cancellationToken)
    {
        await _voucherService.MarkUsedAsync(request.UserId, request.Code, request.OrderId, cancellationToken);
        return Ok();
    }
}

public class InternalValidateVoucherRequestDto : ValidateVoucherRequestDto
{
    public Guid UserId { get; set; }
}
