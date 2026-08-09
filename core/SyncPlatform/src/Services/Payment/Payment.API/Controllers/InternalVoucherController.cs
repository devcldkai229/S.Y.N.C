using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/vouchers")]
public class InternalVoucherController : ControllerBase
{
    private readonly IVoucherService _voucherService;

    public InternalVoucherController(IVoucherService voucherService) => _voucherService = voucherService;

    [HttpGet("{userId:guid}")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<VoucherAvailableItemDto>>>> List(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var items = await _voucherService.GetAvailableAsync(userId, 0m, null, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<VoucherAvailableItemDto>>.SuccessResponse(
            items, "Vouchers retrieved."));
    }

    [HttpPost("apply")]
    public async Task<ActionResult<ApiResponse<ValidateVoucherResponseDto>>> Apply(
        [FromBody] InternalApplyVoucherRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _voucherService.ValidateInternalAsync(
            request.UserId,
            new ValidateVoucherRequestDto
            {
                Code = request.VoucherCode,
                OrderAmount = request.OrderAmount,
                PartnerId = request.PartnerId,
            },
            cancellationToken);
        return Ok(ApiResponse<ValidateVoucherResponseDto>.SuccessResponse(result, "Voucher validated."));
    }
}

public class InternalApplyVoucherRequestDto
{
    public Guid UserId { get; set; }
    public string VoucherCode { get; set; } = string.Empty;
    public Guid? OrderDraftId { get; set; }
    public decimal OrderAmount { get; set; }
    public Guid? PartnerId { get; set; }
}
