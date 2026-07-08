using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Marketplace.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/marketplace/affiliate")]
public class InternalMarketplaceAffiliateController : ControllerBase
{
    private readonly IAffiliateProductService _service;

    public InternalMarketplaceAffiliateController(IAffiliateProductService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<AffiliateProductDto>>>> Search(
        [FromQuery] string? category,
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        var request = new AffiliateProductSearchRequest
        {
            Category = category,
            PageNumber = 1,
            PageSize = Math.Clamp(limit, 1, 30),
        };
        var (items, pagination) = await _service.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<AffiliateProductDto>>.SuccessPagedResponse(
            items, pagination, "Affiliate products retrieved."));
    }
}
