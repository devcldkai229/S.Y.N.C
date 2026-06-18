using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Roadmap.API.Controllers;

[ApiController]
[Route("api/internal/workout-activity")]
[AllowAnonymous]
public class InternalWorkoutActivityController : ControllerBase
{
    private readonly IInternalWorkoutActivityService _service;

    public InternalWorkoutActivityController(IInternalWorkoutActivityService service)
    {
        _service = service;
    }

    [HttpGet("today/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<TodayWorkoutActivityDto>>> GetTodayWorkoutActivity(
        Guid userId,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetTodayWorkoutActivityAsync(userId, timeZoneId, cancellationToken);
        return Ok(ApiResponse<TodayWorkoutActivityDto>.SuccessResponse(result, "Today's workout activity retrieved successfully."));
    }
}
