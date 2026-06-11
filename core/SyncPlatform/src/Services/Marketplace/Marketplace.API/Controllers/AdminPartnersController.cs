using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;

namespace Marketplace.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/admin/partners")]
public class AdminPartnersController : ControllerBase
{
    private readonly IPartnerService _service;

    public AdminPartnersController(IPartnerService service)
    {
        _service = service;
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<ApiResponse<PartnerDto>>> UpdateStatus(
        Guid id,
        [FromBody] UpdatePartnerStatusDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateStatusAsync(id, dto.Status, cancellationToken);
        return Ok(ApiResponse<PartnerDto>.SuccessResponse(result, "Partner status updated successfully."));
    }
}
