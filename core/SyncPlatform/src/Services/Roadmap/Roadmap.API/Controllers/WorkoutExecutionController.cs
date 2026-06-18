using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Services;

namespace Roadmap.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/workout-executions")]
public class WorkoutExecutionController : ControllerBase
{
    private readonly IWorkoutExecutionService _service;
    private readonly ICurrentUserContext _currentUser;

    public WorkoutExecutionController(IWorkoutExecutionService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpPost("start")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionDetailDto>>> Start(
        [FromBody] StartWorkoutExecutionDto request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.StartWorkoutAsync(userId, request, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionDetailDto>.SuccessResponse(result, "Workout execution started successfully."));
    }

    [HttpGet("{executionId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionDetailDto>>> GetById(
        Guid executionId,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.GetWorkoutExecutionDetailAsync(userId, executionId, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionDetailDto>.SuccessResponse(result, "Workout execution retrieved successfully."));
    }

    [HttpPost("{executionId:guid}/finish")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionSummaryDto>>> Finish(
        Guid executionId,
        [FromBody] FinishWorkoutExecutionDto request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.FinishWorkoutAsync(userId, executionId, request, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionSummaryDto>.SuccessResponse(result, "Workout execution finished successfully."));
    }

    [HttpPost("{executionId:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object?>>> Cancel(
        Guid executionId,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        await _service.CancelWorkoutAsync(userId, executionId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Workout execution cancelled successfully."));
    }
}
