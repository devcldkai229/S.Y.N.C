using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Services;
using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Exercise.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/exercises")]
public class ExerciseCatalogController : ControllerBase
{
    private readonly IExerciseCatalogService _service;

    public ExerciseCatalogController(IExerciseCatalogService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ExerciseCatalogDto>>>> Search(
        [FromQuery] ExerciseSearchRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _service.SearchActiveAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ExerciseCatalogDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Exercises retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDto>.SuccessResponse(result, "Exercise retrieved successfully."));
    }

    [HttpGet("{id:guid}/detail")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDetailDto>>> GetDetail(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetDetailAsync(id, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDetailDto>.SuccessResponse(result, "Exercise details retrieved successfully."));
    }

    [HttpGet("code/{code}")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDto>>> GetByCode(string code, CancellationToken cancellationToken)
    {
        var result = await _service.GetByCodeAsync(code, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDto>.SuccessResponse(result, "Exercise retrieved successfully."));
    }

    [HttpGet("slug/{slug}")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDto>>> GetBySlug(string slug, CancellationToken cancellationToken)
    {
        var result = await _service.GetBySlugAsync(slug, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDto>.SuccessResponse(result, "Exercise retrieved successfully."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDto>>> Create([FromBody] CreateExerciseCatalogDto dto, CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<ExerciseCatalogDto>.SuccessResponse(result, "Exercise created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Update(Guid id, [FromBody] UpdateExerciseCatalogDto dto, CancellationToken cancellationToken)
    {
        await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Exercise updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Exercise deleted successfully."));
    }
}
