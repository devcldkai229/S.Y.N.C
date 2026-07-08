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
    private readonly IInternalMarketplaceService _internalService;
    private readonly IPartnerService _partnerService;

    public InternalPartnersController(
        IInternalMarketplaceService internalService,
        IPartnerService partnerService)
    {
        _internalService = internalService;
        _partnerService = partnerService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<PartnerDto>>>> Search(
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        [FromQuery] string? type,
        [FromQuery] string? query,
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        var request = new PartnerSearchRequest
        {
            Query = query,
            Type = type,
            Latitude = lat,
            Longitude = lng,
            PageNumber = 1,
            PageSize = Math.Clamp(limit, 1, 30),
        };
        var (items, pagination) = await _partnerService.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<PartnerDto>>.SuccessPagedResponse(
            items, pagination, "Partners retrieved."));
    }

    [HttpGet("{partnerId:guid}")]
    public async Task<ActionResult<ApiResponse<PartnerInternalDto>>> GetPartner(
        Guid partnerId,
        CancellationToken cancellationToken)
    {
        var result = await _internalService.GetPartnerInternalAsync(partnerId, cancellationToken);
        if (result == null)
            return NotFound(ApiResponse<PartnerInternalDto>.FailureResponse("Partner not found."));

        return Ok(ApiResponse<PartnerInternalDto>.SuccessResponse(result, "Partner retrieved."));
    }
}
