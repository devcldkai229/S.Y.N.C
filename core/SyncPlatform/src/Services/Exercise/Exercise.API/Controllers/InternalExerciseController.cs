using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Exercise.API.Controllers;

[ApiController]
[Route("api/internal/exercises")]
[AllowAnonymous]
public class InternalExerciseController : ControllerBase
{
    private readonly IExerciseCatalogService _catalogService;
    private readonly IExerciseMotionAssetService _motionService;

    public InternalExerciseController(
        IExerciseCatalogService catalogService,
        IExerciseMotionAssetService motionService)
    {
        _catalogService = catalogService;
        _motionService = motionService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ExerciseCatalogDto>>>> Search(
        [FromQuery] string? query,
        [FromQuery] string? muscle,
        [FromQuery] string? equipment,
        [FromQuery] string? difficulty,
        [FromQuery] int limit = 5,
        CancellationToken cancellationToken = default)
    {
        var request = new ExerciseSearchRequest
        {
            Query = query,
            PrimaryMuscle = muscle,
            Equipment = equipment,
            Difficulty = difficulty,
            PageNumber = 1,
            PageSize = Math.Clamp(limit, 1, 20),
        };
        var result = await _catalogService.SearchActiveAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ExerciseCatalogDto>>.SuccessPagedResponse(
            result.Items, result.Pagination, "Exercises retrieved."));
    }

    [HttpGet("{id:guid}/detail")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDetailDto>>> GetDetail(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _catalogService.GetDetailAsync(id, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDetailDto>.SuccessResponse(result, "Exercise detail retrieved."));
    }

    /// <summary>Resolve exercise by slug or search query, then return full catalog detail.</summary>
    [HttpGet("lookup/detail")]
    public async Task<ActionResult<ApiResponse<ExerciseCatalogDetailDto>>> LookupDetail(
        [FromQuery] string? query,
        [FromQuery] string? slug,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(query) && string.IsNullOrWhiteSpace(slug))
        {
            return BadRequest(ApiResponse<object>.FailureResponse("query or slug is required."));
        }

        Guid exerciseId;
        if (!string.IsNullOrWhiteSpace(slug))
        {
            var bySlug = await _catalogService.GetBySlugAsync(slug.Trim(), cancellationToken);
            exerciseId = bySlug.Id;
        }
        else
        {
            var search = await _catalogService.SearchActiveAsync(
                new ExerciseSearchRequest
                {
                    Query = query!.Trim(),
                    PageNumber = 1,
                    PageSize = 1,
                },
                cancellationToken);
            if (search.Items.Count == 0)
            {
                return NotFound(ApiResponse<object>.FailureResponse($"Exercise not found for query '{query}'."));
            }

            exerciseId = search.Items[0].Id;
        }

        var detail = await _catalogService.GetDetailAsync(exerciseId, cancellationToken);
        return Ok(ApiResponse<ExerciseCatalogDetailDto>.SuccessResponse(detail, "Exercise detail retrieved."));
    }

    [HttpGet("{id:guid}/media")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<ExerciseMotionAssetDto>>>> GetMedia(
        Guid id,
        [FromQuery] string? assetType,
        CancellationToken cancellationToken)
    {
        var assets = await _motionService.GetByExerciseIdAsync(id, cancellationToken);
        if (!string.IsNullOrWhiteSpace(assetType))
        {
            assets = assets
                .Where(a => a.AssetType.ToString().Equals(assetType, StringComparison.OrdinalIgnoreCase))
                .ToList();
        }

        return Ok(ApiResponse<IReadOnlyList<ExerciseMotionAssetDto>>.SuccessResponse(
            assets, "Exercise media retrieved."));
    }
}
