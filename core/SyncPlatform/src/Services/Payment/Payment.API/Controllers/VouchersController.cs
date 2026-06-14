using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/payments/vouchers")]
public class VouchersController : ControllerBase
{
    private readonly IVoucherService _voucherService;
    private readonly ICurrentUserContext _currentUser;

    public VouchersController(IVoucherService voucherService, ICurrentUserContext currentUser)
    {
        _voucherService = voucherService;
        _currentUser = currentUser;
    }

    [HttpGet("available")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<VoucherAvailableItemDto>>>> GetAvailable(
        [FromQuery] decimal orderAmount,
        [FromQuery] Guid? partnerId,
        CancellationToken cancellationToken)
    {
        var items = await _voucherService.GetAvailableAsync(
            _currentUser.RequireUserId(), orderAmount, partnerId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<VoucherAvailableItemDto>>.SuccessResponse(items, "Vouchers retrieved."));
    }

    [HttpPost("validate")]
    public async Task<ActionResult<ApiResponse<ValidateVoucherResponseDto>>> Validate(
        [FromBody] ValidateVoucherRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _voucherService.ValidateAsync(_currentUser.RequireUserId(), request, cancellationToken);
        return Ok(ApiResponse<ValidateVoucherResponseDto>.SuccessResponse(result, result.Valid ? "Valid." : result.Message ?? "Invalid."));
    }
}
