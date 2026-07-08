using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/admin/dashboard")]
public class AdminDashboardController : ControllerBase
{
    private readonly IAdminDashboardService _dashboard;

    public AdminDashboardController(IAdminDashboardService dashboard) => _dashboard = dashboard;

    [HttpGet("overview")]
    public async Task<ActionResult<ApiResponse<PaymentDashboardOverviewDto>>> GetOverview(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        var result = await _dashboard.GetOverviewAsync(new DashboardQueryDto { Days = days }, cancellationToken);
        return Ok(ApiResponse<PaymentDashboardOverviewDto>.SuccessResponse(result, "Payment dashboard overview retrieved."));
    }
}
