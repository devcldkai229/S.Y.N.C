using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Marketplace.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/partners")]
public class InternalPartnersController : ControllerBase
{
    private readonly IInternalMarketplaceService _service;

    public InternalPartnersController(IInternalMarketplaceService service) => _service = service;

    [HttpGet("{partnerId:guid}")]
    public async Task<ActionResult<ApiResponse<PartnerInternalDto>>> GetPartner(
        Guid partnerId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetPartnerInternalAsync(partnerId, cancellationToken);
        if (result == null)
            return NotFound(ApiResponse<PartnerInternalDto>.FailureResponse("Partner not found."));

        return Ok(ApiResponse<PartnerInternalDto>.SuccessResponse(result, "Partner retrieved."));
    }
}
