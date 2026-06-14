using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;

namespace Marketplace.API.Controllers;

[ApiController]
[Route("api/v1/food-menu-items")]
public class FoodMenuItemsController : ControllerBase
{
    private readonly IFoodMenuItemService _service;
    private readonly ICurrentUserContext _currentUser;

    public FoodMenuItemsController(IFoodMenuItemService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>>> Search(
        [FromQuery] FoodMenuItemSearchRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _service.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>.SuccessPagedResponse(
            items, pagination, "Food menu items retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<FoodMenuItemDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<FoodMenuItemDto>.SuccessResponse(result, "Food menu item retrieved successfully."));
    }

    [HttpPost("partners/{partnerId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<FoodMenuItemDto>>> Create(
        Guid partnerId,
        [FromBody] CreateFoodMenuItemDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(_currentUser.RequireUserId(), partnerId, dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<FoodMenuItemDto>.SuccessResponse(result, "Food menu item created successfully."));
    }

    [HttpPut("partners/{partnerId:guid}/{itemId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<FoodMenuItemDto>>> Update(
        Guid partnerId,
        Guid itemId,
        [FromBody] UpdateFoodMenuItemDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(_currentUser.RequireUserId(), partnerId, itemId, dto, cancellationToken);
        return Ok(ApiResponse<FoodMenuItemDto>.SuccessResponse(result, "Food menu item updated successfully."));
    }

    [HttpDelete("partners/{partnerId:guid}/{itemId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid partnerId,
        Guid itemId,
        CancellationToken cancellationToken)
    {
        await _service.SoftDeleteAsync(_currentUser.RequireUserId(), partnerId, itemId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Food menu item deleted successfully."));
    }
}
