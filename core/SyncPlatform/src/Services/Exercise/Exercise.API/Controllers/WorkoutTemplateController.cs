using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Services;
using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Exercise.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/workout-templates")]
public class WorkoutTemplateController : ControllerBase
{
    private readonly IWorkoutTemplateService _service;

    public WorkoutTemplateController(IWorkoutTemplateService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<WorkoutTemplateDto>>>> GetAll(
        [FromQuery] PaginationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(request.PageNumber, request.PageSize, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<WorkoutTemplateDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Workout templates retrieved successfully."));
    }

    [HttpGet("system")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<WorkoutTemplateDto>>>> GetSystemTemplates(
        [FromQuery] PaginationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetSystemTemplatesAsync(request.PageNumber, request.PageSize, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<WorkoutTemplateDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "System templates retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<WorkoutTemplateDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<WorkoutTemplateDto>.SuccessResponse(result, "Workout template retrieved successfully."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<WorkoutTemplateDto>>> Create([FromBody] CreateWorkoutTemplateDto dto, CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<WorkoutTemplateDto>.SuccessResponse(result, "Workout template created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Update(Guid id, [FromBody] UpdateWorkoutTemplateDto dto, CancellationToken cancellationToken)
    {
        await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Workout template updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Workout template deleted successfully."));
    }
}
