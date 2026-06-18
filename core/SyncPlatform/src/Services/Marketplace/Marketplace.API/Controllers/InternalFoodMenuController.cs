using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Marketplace.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/food-menu")]
public class InternalFoodMenuController : ControllerBase
{
    private readonly IInternalMarketplaceService _service;

    public InternalFoodMenuController(IInternalMarketplaceService service) => _service = service;

    [HttpPost("validate-order")]
    public async Task<ActionResult<ApiResponse<ValidateOrderItemsResultDto>>> ValidateOrderItems(
        [FromBody] ValidateOrderItemsRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.ValidateOrderItemsAsync(request, cancellationToken);
        return Ok(ApiResponse<ValidateOrderItemsResultDto>.SuccessResponse(result, "Validation completed."));
    }
}
