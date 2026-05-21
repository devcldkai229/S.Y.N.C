using Microsoft.AspNetCore.Mvc;
using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Services;

namespace Roadmap.API.Controllers;

[ApiController]
[Route("api/v1/workouts")]
public class UserCustomWorkoutController : ControllerBase
{
    private readonly IUserCustomWorkoutService _service;

    public UserCustomWorkoutController(IUserCustomWorkoutService service)
    {
        _service = service;
    }

    /// <summary>
    /// Task 5 — Create a custom workout template for a user.
    /// POST /api/v1/workouts/custom
    /// </summary>
    [HttpPost("custom")]
    [ProducesResponseType(typeof(ApiResponse<UserCustomWorkoutDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ApiResponse<UserCustomWorkoutDto>>> CreateCustomWorkout(
        [FromBody] CreateUserCustomWorkoutDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<UserCustomWorkoutDto>.SuccessResponse(result, "Custom workout created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<UserCustomWorkoutDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserCustomWorkoutDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<UserCustomWorkoutDto>.SuccessResponse(result, "Custom workout retrieved successfully."));
    }

    [HttpGet("user/{userId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>>> GetByUser(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<UserCustomWorkoutDto>>.SuccessResponse(result, "Custom workouts retrieved successfully."));
    }
}
