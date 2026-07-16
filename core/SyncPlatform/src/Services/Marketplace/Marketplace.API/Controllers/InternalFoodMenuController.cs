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
    private readonly IInternalMarketplaceService _internalService;
    private readonly IFoodMenuItemService _foodMenuService;

    public InternalFoodMenuController(
        IInternalMarketplaceService internalService,
        IFoodMenuItemService foodMenuService)
    {
        _internalService = internalService;
        _foodMenuService = foodMenuService;
    }

    [HttpGet("item/{foodMenuItemId:guid}")]
    public async Task<ActionResult<ApiResponse<FoodMenuItemDto>>> GetItem(
        Guid foodMenuItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await _foodMenuService.GetByIdAsync(foodMenuItemId, cancellationToken);
        return Ok(ApiResponse<FoodMenuItemDto>.SuccessResponse(item, "Food menu item retrieved."));
    }

    /// <summary>
    /// GET /api/internal/food-menu/search — cross-partner dish search for AI.
    /// Must be declared before {partnerId} routes.
    /// </summary>
    [HttpGet("search")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>>> Search(
        [FromQuery] string? query,
        [FromQuery] Guid? partnerId,
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        [FromQuery] double? radiusKm,
        [FromQuery] decimal? minRating,
        [FromQuery] int limit = 20,
        CancellationToken cancellationToken = default)
    {
        var request = new FoodMenuItemSearchRequest
        {
            Query = query,
            PartnerId = partnerId,
            Latitude = lat,
            Longitude = lng,
            RadiusKm = radiusKm,
            PageNumber = 1,
            PageSize = Math.Clamp(limit, 1, 50),
        };
        var (items, pagination) = await _foodMenuService.SearchAsync(request, cancellationToken);
        if (minRating is decimal min)
        {
            items = items.Where(i => i.RatingAverage >= min).ToList();
            pagination = new PaginationMetadata(1, request.PageSize, items.Count);
        }

        return Ok(PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>.SuccessPagedResponse(
            items, pagination, "Food menu search completed."));
    }

    [HttpGet("{partnerId:guid}")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>>> GetMenu(
        Guid partnerId,
        [FromQuery] int limit = 30,
        CancellationToken cancellationToken = default)
    {
        var request = new FoodMenuItemSearchRequest
        {
            PartnerId = partnerId,
            PageNumber = 1,
            PageSize = Math.Clamp(limit, 1, 50),
        };
        var (items, pagination) = await _foodMenuService.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<FoodMenuItemDto>>.SuccessPagedResponse(
            items, pagination, "Menu retrieved."));
    }

    [HttpPost("validate-order")]
    public async Task<ActionResult<ApiResponse<ValidateOrderItemsResultDto>>> ValidateOrderItems(
        [FromBody] ValidateOrderItemsRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _internalService.ValidateOrderItemsAsync(request, cancellationToken);
        return Ok(ApiResponse<ValidateOrderItemsResultDto>.SuccessResponse(result, "Validation completed."));
    }
}
