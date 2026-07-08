using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Marketplace.API.Controllers;

/// <summary>AI meal recommendations (internal API key).</summary>
[ApiController]
[Route("api/internal/marketplace")]
[AllowAnonymous]
public class InternalMarketplaceRecommendationsController : ControllerBase
{
    private readonly IFoodMenuItemService _foodMenuItemService;

    public InternalMarketplaceRecommendationsController(IFoodMenuItemService foodMenuItemService)
    {
        _foodMenuItemService = foodMenuItemService;
    }

    [HttpGet("recommendations")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<FoodMenuItemDto>>>> GetRecommendations(
        [FromQuery] Guid userId,
        [FromQuery] string? goal,
        [FromQuery] decimal? maxPrice,
        CancellationToken cancellationToken)
    {
        _ = userId;

        var request = new FoodMenuItemSearchRequest
        {
            Query = string.IsNullOrWhiteSpace(goal) ? null : goal,
            MaxPrice = maxPrice is > 0 ? maxPrice : 150_000m,
            IsAiRecommendedOnly = true,
            PageNumber = 1,
            PageSize = 10,
        };

        var (items, _) = await _foodMenuItemService.SearchAsync(request, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<FoodMenuItemDto>>.SuccessResponse(
            items,
            "AI meal recommendations retrieved."));
    }
}
