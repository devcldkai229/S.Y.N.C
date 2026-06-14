using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Notification.Application.Common;
using Notification.Application.DTOs;
using Notification.Application.Services;

namespace Notification.API.Controllers;

[ApiController]
[Route("api/internal/notifications")]
[AllowAnonymous]
public class InternalNotificationController : ControllerBase
{
    private readonly INotificationService _service;

    public InternalNotificationController(INotificationService service)
    {
        _service = service;
    }

    /// <summary>
    /// Called by internal services (IAM, Social, etc.) to deliver in-app notifications.
    /// Protected by X-Internal-Api-Key middleware — no JWT required.
    /// </summary>
    [HttpPost("send")]
    public async Task<ActionResult<ApiResponse<object>>> Send(
        [FromBody] SendNotificationDto dto,
        CancellationToken cancellationToken)
    {
        await _service.SendNotificationAsync(dto, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, "Notification sent."));
    }
}
