using Notification.Application.Common;
using Notification.Application.DTOs;
using Notification.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Notification.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/templates")]
public class NotificationTemplateController : ControllerBase
{
    private readonly INotificationTemplateService _service;

    public NotificationTemplateController(INotificationTemplateService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<NotificationTemplateDto>>>> GetAll(CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<NotificationTemplateDto>>.SuccessResponse(result, "Templates retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<NotificationTemplateDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<NotificationTemplateDto>.SuccessResponse(result, "Template retrieved successfully."));
    }

    [HttpGet("code/{code}")]
    public async Task<ActionResult<ApiResponse<NotificationTemplateDto>>> GetByCode(string code, CancellationToken cancellationToken)
    {
        var result = await _service.GetByCodeAsync(code, cancellationToken);
        return Ok(ApiResponse<NotificationTemplateDto>.SuccessResponse(result, "Template retrieved successfully."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<NotificationTemplateDto>>> Create(
        [FromBody] CreateNotificationTemplateDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, ApiResponse<NotificationTemplateDto>.SuccessResponse(result, "Template created successfully."));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Update(
        Guid id,
        [FromBody] UpdateNotificationTemplateDto dto,
        CancellationToken cancellationToken)
    {
        await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Template updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Template deleted successfully."));
    }

    [HttpPatch("{id:guid}/toggle-status")]
    public async Task<ActionResult<ApiResponse<object?>>> ToggleStatus(Guid id, CancellationToken cancellationToken)
    {
        await _service.ToggleStatusAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Template status toggled successfully."));
    }
}
