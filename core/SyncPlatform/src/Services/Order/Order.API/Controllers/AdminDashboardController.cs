using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Common;
using Order.Application.DTOs;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/admin/dashboard")]
public class AdminDashboardController : ControllerBase
{
    private readonly IAdminDashboardService _dashboard;

    public AdminDashboardController(IAdminDashboardService dashboard) => _dashboard = dashboard;

    [HttpGet("overview")]
    public async Task<ActionResult<ApiResponse<OrderDashboardOverviewDto>>> GetOverview(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        var result = await _dashboard.GetOverviewAsync(new DashboardQueryDto { Days = days }, cancellationToken);
        return Ok(ApiResponse<OrderDashboardOverviewDto>.SuccessResponse(result, "Order dashboard overview retrieved."));
    }
}
