using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/social/reports")]
public class ContentReportController : ControllerBase
{
    private readonly IContentReportService _reports;
    private readonly ICurrentUserContext _currentUser;

    public ContentReportController(IContentReportService reports, ICurrentUserContext currentUser)
    {
        _reports = reports;
        _currentUser = currentUser;
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ContentReportDto>>> Create(
        [FromBody] CreateContentReportDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _reports.CreateAsync(
            _currentUser.RequireUserId(),
            dto,
            cancellationToken);
        return Ok(ApiResponse<ContentReportDto>.SuccessResponse(result, "Report submitted."));
    }
}
