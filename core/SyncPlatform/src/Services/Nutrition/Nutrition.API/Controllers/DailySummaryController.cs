using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/daily-summary")]
public class DailySummaryController : ControllerBase
{
    private readonly IDailyNutritionSummaryService _service;
    private readonly ICurrentUserContext _currentUser;

    public DailySummaryController(IDailyNutritionSummaryService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<DailyNutritionSummaryDto>>> Get(
        [FromQuery] DateOnly? date,
        CancellationToken cancellationToken)
    {
        var targetDate = date ?? DateOnly.FromDateTime(DateTimeOffset.UtcNow.UtcDateTime);
        var result = await _service.GetDailySummaryAsync(_currentUser.RequireUserId(), targetDate, cancellationToken);
        return Ok(ApiResponse<DailyNutritionSummaryDto>.SuccessResponse(result, "Daily summary retrieved successfully."));
    }

    [HttpPost("water")]
    public async Task<ActionResult<ApiResponse<DailyNutritionSummaryDto>>> AddWater(
        [FromBody] AddWaterIntakeDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.AddWaterIntakeAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<DailyNutritionSummaryDto>.SuccessResponse(result, "Water intake updated successfully."));
    }
}
