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
[Route("api/v1/scheduled-workouts")]
public class ScheduledWorkoutController : ControllerBase
{
    private readonly IScheduledWorkoutService _service;
    private readonly ICurrentUserContext _currentUser;

    public ScheduledWorkoutController(IScheduledWorkoutService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<ScheduledWorkoutDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ScheduledWorkoutDto>>> Create(
        [FromBody] CreateScheduledWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<ScheduledWorkoutDto>.SuccessResponse(result, "Scheduled workout created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ScheduledWorkoutDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ScheduledWorkoutDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<ScheduledWorkoutDto>.SuccessResponse(result, "Scheduled workout retrieved successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<ScheduledWorkoutDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ScheduledWorkoutDto>>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var targetUserId = userId ?? _currentUser.RequireUserId();
        var (items, metadata) = await _service.GetPagedAsync(pageNumber, pageSize, targetUserId, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ScheduledWorkoutDto>>.SuccessPagedResponse(items, metadata, "Scheduled workouts retrieved successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ScheduledWorkoutDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ScheduledWorkoutDto>>> Update(
        Guid id,
        [FromBody] UpdateScheduledWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();
        var result = await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<ScheduledWorkoutDto>.SuccessResponse(result, "Scheduled workout updated successfully."));
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
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Scheduled workout deleted successfully."));
    }

}
