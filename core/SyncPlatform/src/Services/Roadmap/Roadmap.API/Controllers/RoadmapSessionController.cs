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
[Route("api/v1/sessions")]
public class RoadmapSessionController : ControllerBase
{
    private readonly IRoadmapSessionService _sessionService;
    private readonly IWorkoutExecutionService _executionService;
    private readonly ICurrentUserContext _currentUser;

    public RoadmapSessionController(
        IRoadmapSessionService sessionService,
        IWorkoutExecutionService executionService,
        ICurrentUserContext currentUser)
    {
        _sessionService = sessionService;
        _executionService = executionService;
        _currentUser = currentUser;
    }

    /// <summary>
    /// AI Flow — Schedule a workout session with explicit ExecutionBlocks.
    /// RoadmapId can be null for free (non-roadmap) sessions.
    /// POST /api/v1/sessions/schedule
    /// </summary>
    [HttpPost("schedule")]
    [ProducesResponseType(typeof(ApiResponse<ScheduledSessionResultDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ScheduledSessionResultDto>>> Schedule(
        [FromBody] ScheduleSessionDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();

        var result = await _sessionService.ScheduleAsync(dto, cancellationToken);
        var response = ApiResponse<ScheduledSessionResultDto>.SuccessResponse(result, "Session scheduled successfully.");
        return CreatedAtAction(nameof(GetById), new { sessionId = result.Session.Id }, response);
    }

    /// <summary>
    /// Custom Flow — Create a session from an existing UserCustomWorkout template,
    /// then schedule it at the requested date/time.
    /// The original UserCustomWorkout is NOT modified (reusable template).
    /// POST /api/v1/sessions/from-custom/{customWorkoutId}
    /// </summary>
    [HttpPost("from-custom/{customWorkoutId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ScheduledSessionResultDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ScheduledSessionResultDto>>> ScheduleFromCustomWorkout(
        Guid customWorkoutId,
        [FromBody] ScheduleFromCustomWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();

        var result = await _sessionService.ScheduleFromCustomWorkoutAsync(customWorkoutId, dto, cancellationToken);
        var response = ApiResponse<ScheduledSessionResultDto>.SuccessResponse(result, "Session created from custom workout and scheduled successfully.");
        return CreatedAtAction(nameof(GetById), new { sessionId = result.Session.Id }, response);
    }

    [HttpGet("{sessionId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<RoadmapSessionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<RoadmapSessionDto>>> GetById(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var result = await _sessionService.GetByIdAsync(sessionId, cancellationToken);
        return Ok(ApiResponse<RoadmapSessionDto>.SuccessResponse(result, "Session retrieved successfully."));
    }

    [HttpGet("roadmap/{roadmapId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<RoadmapSessionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<RoadmapSessionDto>>>> GetByRoadmap(
        Guid roadmapId,
        CancellationToken cancellationToken)
    {
        var result = await _sessionService.GetByRoadmapIdAsync(roadmapId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<RoadmapSessionDto>>.SuccessResponse(result, "Sessions retrieved successfully."));
    }

    /// <summary>
    /// Task 6 — Submit actual workout execution results for a session.
    /// POST /api/v1/sessions/{sessionId}/execute
    /// </summary>
    [HttpPost("{sessionId:guid}/execute")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionResultDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionResultDto>>> Execute(
        Guid sessionId,
        [FromBody] SubmitWorkoutExecutionDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();

        var result = await _executionService.SubmitExecutionAsync(sessionId, dto, cancellationToken);
        var response = ApiResponse<WorkoutExecutionResultDto>.SuccessResponse(result, "Workout execution logged successfully.");
        return CreatedAtAction(nameof(GetById), new { sessionId }, response);
    }
}
