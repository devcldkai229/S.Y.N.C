using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/internal/smart-push")]
[AllowAnonymous]
public class InternalSmartPushController : ControllerBase
{
    private readonly IInternalSmartPushService _service;

    public InternalSmartPushController(IInternalSmartPushService service)
    {
        _service = service;
    }

    [HttpGet("due-users")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<DueSmartPushUserDto>>>> GetDueUsers(
        [FromQuery] DateTime utcNow,
        CancellationToken cancellationToken)
    {
        var utcNowUtc = utcNow.Kind == DateTimeKind.Unspecified 
            ? DateTime.SpecifyKind(utcNow, DateTimeKind.Utc) 
            : utcNow.ToUniversalTime();

        var result = await _service.GetDueUsersAsync(utcNowUtc, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<DueSmartPushUserDto>>.SuccessResponse(result, "Due users retrieved successfully."));
    }

    [HttpGet("context/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<IamSmartPushContextDto>>> GetSmartPushContext(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetSmartPushContextAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<IamSmartPushContextDto>.FailureResponse($"Smart push context not found for user {userId}."));
        }

        return Ok(ApiResponse<IamSmartPushContextDto>.SuccessResponse(result, "User smart push context retrieved successfully."));
    }
}
