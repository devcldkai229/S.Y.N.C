using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/admin/dashboard")]
public class AdminDashboardController : ControllerBase
{
    private readonly IAdminDashboardService _dashboard;

    public AdminDashboardController(IAdminDashboardService dashboard) => _dashboard = dashboard;

    [HttpGet("overview")]
    public async Task<ActionResult<ApiResponse<IamDashboardOverviewDto>>> GetOverview(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        var result = await _dashboard.GetOverviewAsync(new DashboardQueryDto { Days = days }, cancellationToken);
        return Ok(ApiResponse<IamDashboardOverviewDto>.SuccessResponse(result, "Dashboard overview retrieved."));
    }
}
