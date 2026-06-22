using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

[ApiController]
[Route("api/internal/nutrition")]
[AllowAnonymous]
public class InternalNutritionController : ControllerBase
{
    private readonly IDailyNutritionSummaryService _service;

    public InternalNutritionController(IDailyNutritionSummaryService service)
    {
        _service = service;
    }

    [HttpGet("summary/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<DailyNutritionSummaryDto>>> GetDailySummary(
        Guid userId,
        [FromQuery] DateOnly? date,
        CancellationToken cancellationToken)
    {
        var targetDate = date ?? DateOnly.FromDateTime(DateTimeOffset.UtcNow.UtcDateTime);
        var result = await _service.GetDailySummaryAsync(userId, targetDate, cancellationToken);
        return Ok(ApiResponse<DailyNutritionSummaryDto>.SuccessResponse(result, "Daily summary retrieved successfully."));
    }
}
