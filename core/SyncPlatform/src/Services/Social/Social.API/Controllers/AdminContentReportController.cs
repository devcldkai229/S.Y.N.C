using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize(Roles = "SystemAdmin")]
[Route("api/v1/social/admin/reports")]
public class AdminContentReportController : ControllerBase
{
    private readonly IContentReportService _reports;

    public AdminContentReportController(IContentReportService reports)
    {
        _reports = reports;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<AdminContentReportDto>>>> List(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var (items, pagination) = await _reports.ListAdminAsync(status, page, pageSize, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<AdminContentReportDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Reports retrieved."));
    }

    [HttpPatch("{id:guid}")]
    public async Task<ActionResult<ApiResponse<AdminContentReportDto>>> Resolve(
        Guid id,
        [FromBody] ResolveContentReportDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _reports.ResolveAsync(id, dto.Status, dto.HidePost, cancellationToken);
        return Ok(ApiResponse<AdminContentReportDto>.SuccessResponse(result, "Report updated."));
    }
}
