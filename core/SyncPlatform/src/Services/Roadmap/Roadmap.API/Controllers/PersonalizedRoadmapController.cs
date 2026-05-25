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
[Route("api/v1/roadmaps")]
public class PersonalizedRoadmapController : ControllerBase
{
    private readonly IPersonalizedRoadmapService _service;
    private readonly ICurrentUserContext _currentUser;

    public PersonalizedRoadmapController(IPersonalizedRoadmapService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<PersonalizedRoadmapDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> Create(
        [FromBody] CreatePersonalizedRoadmapDto dto,
        CancellationToken cancellationToken)
    {
        dto.UserId = _currentUser.RequireUserId();
        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Personalized roadmap created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<PersonalizedRoadmapDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Personalized roadmap retrieved successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<PersonalizedRoadmapDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<PersonalizedRoadmapDto>>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var targetUserId = userId ?? _currentUser.RequireUserId();
        var (items, metadata) = await _service.GetPagedAsync(pageNumber, pageSize, targetUserId, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<PersonalizedRoadmapDto>>.SuccessPagedResponse(items, metadata, "Personalized roadmaps retrieved successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<PersonalizedRoadmapDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> Update(
        Guid id,
        [FromBody] UpdatePersonalizedRoadmapDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Personalized roadmap updated successfully."));
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
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Personalized roadmap deleted successfully."));
    }

}
