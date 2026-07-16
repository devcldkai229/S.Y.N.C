using Libs.Shared.Time;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

/// <summary>Internal endpoints for SYNC AI Layer (X-Internal-Api-Key).</summary>
[ApiController]
[Route("api/internal/nutrition")]
[AllowAnonymous]
public class InternalNutritionController : ControllerBase
{
    private readonly IDailyNutritionSummaryService _dailySummaryService;
    private readonly IMealLogService _mealLogService;
    private readonly IFoodItemService _foodItemService;

    public InternalNutritionController(
        IDailyNutritionSummaryService dailySummaryService,
        IMealLogService mealLogService,
        IFoodItemService foodItemService)
    {
        _dailySummaryService = dailySummaryService;
        _mealLogService = mealLogService;
        _foodItemService = foodItemService;
    }

    [HttpGet("daily-summary/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<DailyNutritionSummaryDto>>> GetDailySummary(
        Guid userId,
        [FromQuery] DateOnly? date,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        var targetDate = date ?? UserLocalTime.TodayDate(timeZoneId);
        var result = await _dailySummaryService.GetDailySummaryAsync(userId, targetDate, cancellationToken);
        return Ok(ApiResponse<DailyNutritionSummaryDto>.SuccessResponse(result, "Daily summary retrieved."));
    }

    [HttpGet("{userId:guid}/timeseries")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<NutritionTimeseriesBucketDto>>>> GetTimeseries(
        Guid userId,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] string? granularity,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        var end = to ?? UserLocalTime.TodayDate(timeZoneId);
        var start = from ?? end.AddDays(-13);
        var result = await _dailySummaryService.GetTimeseriesAsync(
            userId, start, end, granularity ?? "day", cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<NutritionTimeseriesBucketDto>>.SuccessResponse(
            result, "Nutrition timeseries retrieved."));
    }

    [HttpPost("meal-logs")]
    public async Task<ActionResult<ApiResponse<MealLogDto>>> CreateMealLog(
        [FromBody] InternalCreateMealLogRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _mealLogService.CreateAsync(request.UserId, request, cancellationToken);
        return Ok(ApiResponse<MealLogDto>.SuccessResponse(result, "Meal log created."));
    }

    [HttpGet("food-items")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<FoodItemDto>>>> SearchFood(
        [FromQuery] string? query,
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        var request = new FoodSearchRequest { Query = query, PageNumber = 1, PageSize = Math.Clamp(limit, 1, 50) };
        var (items, pagination) = await _foodItemService.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<FoodItemDto>>.SuccessPagedResponse(
            items, pagination, "Food items retrieved."));
    }

    [HttpGet("food-items/barcode/{barcode}")]
    public async Task<ActionResult<ApiResponse<FoodItemDto>>> GetFoodByBarcode(
        string barcode,
        CancellationToken cancellationToken)
    {
        var result = await _foodItemService.GetByBarcodeAsync(barcode, cancellationToken);
        return Ok(ApiResponse<FoodItemDto>.SuccessResponse(result, "Food retrieved."));
    }

    [HttpPost("water-intake")]
    public async Task<ActionResult<ApiResponse<DailyNutritionSummaryDto>>> LogWater(
        [FromBody] InternalWaterIntakeRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _dailySummaryService.AddWaterIntakeAsync(
            request.UserId,
            new AddWaterIntakeDto { Milliliters = request.Milliliters },
            cancellationToken);
        return Ok(ApiResponse<DailyNutritionSummaryDto>.SuccessResponse(result, "Water intake logged."));
    }
}

/// <summary>userId + fields from <see cref="CreateMealLogDto"/>.</summary>
public class InternalCreateMealLogRequestDto : CreateMealLogDto
{
    public Guid UserId { get; set; }
}

public class InternalWaterIntakeRequestDto
{
    public Guid UserId { get; set; }

    public int Milliliters { get; set; }
}
