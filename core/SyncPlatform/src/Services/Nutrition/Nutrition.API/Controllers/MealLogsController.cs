using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/meal-logs")]
public class MealLogsController : ControllerBase
{
    private readonly IMealLogService _service;
    private readonly ICurrentUserContext _currentUser;

    public MealLogsController(IMealLogService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<MealLogDto>>>> List(
        [FromQuery] MealLogListRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _service.ListAsync(_currentUser.RequireUserId(), request, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<MealLogDto>>.SuccessResponse(result, "Meal logs retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<MealLogDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<MealLogDto>.SuccessResponse(result, "Meal log retrieved successfully."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<MealLogDto>>> Create(
        [FromBody] CreateMealLogDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<MealLogDto>.SuccessResponse(result, "Meal log created successfully."));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ApiResponse<MealLogDto>>> Update(
        Guid id,
        [FromBody] UpdateMealLogDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(_currentUser.RequireUserId(), id, dto, cancellationToken);
        return Ok(ApiResponse<MealLogDto>.SuccessResponse(result, "Meal log updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Meal log deleted successfully."));
    }
}
