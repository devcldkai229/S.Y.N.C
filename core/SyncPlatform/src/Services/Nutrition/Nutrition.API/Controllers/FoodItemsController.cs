using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

[ApiController]
[Route("api/v1/foods")]
public class FoodItemsController : ControllerBase
{
    private readonly IFoodItemService _service;

    public FoodItemsController(IFoodItemService service)
    {
        _service = service;
    }

    [HttpGet]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<FoodItemDto>>>> Search(
        [FromQuery] FoodSearchRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _service.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<FoodItemDto>>.SuccessPagedResponse(
            items, pagination, "Foods retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<ApiResponse<FoodItemDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<FoodItemDto>.SuccessResponse(result, "Food retrieved successfully."));
    }

    [HttpGet("barcode/{barcode}")]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<ApiResponse<FoodItemDto>>> GetByBarcode(string barcode, CancellationToken cancellationToken)
    {
        var result = await _service.GetByBarcodeAsync(barcode, cancellationToken);
        return Ok(ApiResponse<FoodItemDto>.SuccessResponse(result, "Food retrieved successfully."));
    }

    [HttpPost]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<ApiResponse<FoodItemDto>>> CreateUserFood(
        [FromBody] CreateUserFoodItemDto dto,
        CancellationToken cancellationToken)
    {
        var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
        var result = await _service.CreateUserSubmittedAsync(userId, dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<FoodItemDto>.SuccessResponse(result, "Food created successfully."));
    }

    [HttpPost("admin/import")]
    [Authorize(Policy = AuthPolicies.AdminOnly)]
    public async Task<ActionResult<ApiResponse<int>>> ImportSystemFoods(
        [FromBody] ImportSystemFoodItemsRequest request,
        CancellationToken cancellationToken)
    {
        var count = await _service.ImportSystemFoodsAsync(request, cancellationToken);
        return Ok(ApiResponse<int>.SuccessResponse(count, $"{count} foods imported successfully."));
    }
}
