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
[Route("api/v1/workouts")]
public class UserCustomWorkoutController : ControllerBase
{
    private readonly IUserCustomWorkoutService _service;
    private readonly ICurrentUserContext _currentUser;

    public UserCustomWorkoutController(IUserCustomWorkoutService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    /// <summary>
    /// Task 5 — Create a custom workout template for the authenticated user.
    /// POST /api/v1/workouts/custom
    /// </summary>
    [HttpPost("custom")]
    [ProducesResponseType(typeof(ApiResponse<UserCustomWorkoutDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<UserCustomWorkoutDto>>> CreateCustomWorkout(
        [FromBody] CreateUserCustomWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        // Always derive ownership from the JWT — never trust the body.
        dto.UserId = _currentUser.RequireUserId();

        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<UserCustomWorkoutDto>.SuccessResponse(result, "Custom workout created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<UserCustomWorkoutDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserCustomWorkoutDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<UserCustomWorkoutDto>.SuccessResponse(result, "Custom workout retrieved successfully."));
    }

    /// <summary>
    /// List the authenticated user's custom workouts. Admins may pass any userId; everyone else
    /// can only query their own templates (enforced server-side).
    /// </summary>
    [HttpGet("user/{userId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>>> GetByUser(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var currentUserId = _currentUser.RequireUserId();
        var isAdmin       = string.Equals(_currentUser.Role, "SystemAdmin", StringComparison.Ordinal);
        if (!isAdmin && userId != currentUserId)
            return StatusCode(StatusCodes.Status403Forbidden,
                ApiResponse<object>.FailureResponse("You can only query your own custom workouts."));

        var result = await _service.GetByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>.SuccessResponse(result, "Custom workouts retrieved successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<UserCustomWorkoutDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<UserCustomWorkoutDto>>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var targetUserId = userId ?? _currentUser.RequireUserId();
        var (items, metadata) = await _service.GetPagedAsync(pageNumber, pageSize, targetUserId, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<UserCustomWorkoutDto>>.SuccessPagedResponse(items, metadata, "Custom workouts retrieved successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<UserCustomWorkoutDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserCustomWorkoutDto>>> Update(
        Guid id,
        [FromBody] UpdateUserCustomWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<UserCustomWorkoutDto>.SuccessResponse(result, "Custom workout updated successfully."));
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
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Custom workout deleted successfully."));
    }

}

