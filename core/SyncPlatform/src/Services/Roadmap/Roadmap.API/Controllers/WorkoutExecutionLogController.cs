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
[Route("api/v1/execution-logs")]
public class WorkoutExecutionLogController : ControllerBase
{
    private readonly IWorkoutExecutionLogService _service;
    private readonly ICurrentUserContext _currentUser;

    public WorkoutExecutionLogController(IWorkoutExecutionLogService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionLogDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionLogDto>>> Create(
        [FromBody] CreateWorkoutExecutionLogDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<WorkoutExecutionLogDto>.SuccessResponse(result, "Workout execution log created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionLogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionLogDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionLogDto>.SuccessResponse(result, "Workout execution log retrieved successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var targetUserId = userId ?? _currentUser.RequireUserId();
        var (items, metadata) = await _service.GetPagedAsync(pageNumber, pageSize, targetUserId, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>.SuccessPagedResponse(items, metadata, "Workout execution logs retrieved successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<WorkoutExecutionLogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionLogDto>>> Update(
        Guid id,
        [FromBody] UpdateWorkoutExecutionLogDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();
        var result = await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionLogDto>.SuccessResponse(result, "Workout execution log updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Workout execution log deleted successfully."));
    }

}
