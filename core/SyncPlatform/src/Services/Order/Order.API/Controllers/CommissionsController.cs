using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/commissions")]
public class CommissionsController : ControllerBase
{
    private readonly ICommissionService _commissionService;

    public CommissionsController(ICommissionService commissionService) => _commissionService = commissionService;

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<CommissionRecordDto>>>> List(
        [FromQuery] CommissionListRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _commissionService.ListAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<CommissionRecordDto>>.SuccessPagedResponse(items, pagination, "Commissions retrieved."));
    }

    [HttpGet("revenue-summary")]
    public async Task<ActionResult<ApiResponse<CommissionRevenueSummaryDto>>> RevenueSummary(
        [FromQuery] CommissionListRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _commissionService.GetRevenueSummaryAsync(request, cancellationToken);
        return Ok(ApiResponse<CommissionRevenueSummaryDto>.SuccessResponse(result, "Revenue summary retrieved."));
    }

    [HttpPost("affiliate/reconcile")]
    public async Task<ActionResult<ApiResponse<int>>> ReconcileAffiliate(
        [FromBody] AffiliateReconcileRequest request,
        CancellationToken cancellationToken)
    {
        var count = await _commissionService.ReconcileAffiliateAsync(request, cancellationToken);
        return Ok(ApiResponse<int>.SuccessResponse(count, $"{count} affiliate commission records created."));
    }

    [HttpPatch("{id:guid}/mark-paid")]
    public async Task<ActionResult<ApiResponse<CommissionRecordDto>>> MarkPaid(
        Guid id,
        [FromBody] MarkCommissionPaidDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _commissionService.MarkPaidAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<CommissionRecordDto>.SuccessResponse(result, "Commission marked as paid."));
    }
}
