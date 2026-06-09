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
[Route("api/v1/exercise-set-logs")]
public class ExerciseSetLogController : ControllerBase
{
    private readonly IExerciseSetLogService _service;
    private readonly ICurrentUserContext _currentUser;

    public ExerciseSetLogController(IExerciseSetLogService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<ExerciseSetLogDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ExerciseSetLogDto>>> Create(
        [FromBody] CreateExerciseSetLogDto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.CreateAsync(userId, dto, cancellationToken);
        var response = ApiResponse<ExerciseSetLogDto>.SuccessResponse(result, "Exercise set log created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ExerciseSetLogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ExerciseSetLogDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<ExerciseSetLogDto>.SuccessResponse(result, "Exercise set log retrieved successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<ExerciseSetLogDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ExerciseSetLogDto>>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? executionId = null,
        CancellationToken cancellationToken = default)
    {
        var (items, metadata) = await _service.GetPagedAsync(pageNumber, pageSize, executionId, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ExerciseSetLogDto>>.SuccessPagedResponse(items, metadata, "Exercise set logs retrieved successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ExerciseSetLogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ExerciseSetLogDto>>> Update(
        Guid id,
        [FromBody] UpdateExerciseSetLogDto request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.UpdateAsync(userId, id, request, cancellationToken);
        return Ok(ApiResponse<ExerciseSetLogDto>.SuccessResponse(result, "Exercise set log updated successfully."));
    }
}
