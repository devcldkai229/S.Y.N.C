using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

/// <summary>
/// Endpoint nội bộ phục vụ SYNC AI Layer. Bảo vệ bởi InternalApiKeyMiddleware
/// (prefix /api/internal + header X-Internal-Api-Key).
/// </summary>
[ApiController]
[Route("api/internal/ai-context")]
[AllowAnonymous]
public class InternalAiContextController : ControllerBase
{
    private readonly IInternalAiContextService _service;

    public InternalAiContextController(IInternalAiContextService service)
    {
        _service = service;
    }

    [HttpGet("{userId:guid}/full-context")]
    public async Task<ActionResult<ApiResponse<InternalAiContextDto>>> GetFullContext(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetFullContextAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalAiContextDto>.FailureResponse(
                $"User {userId} not found."));
        }

        return Ok(ApiResponse<InternalAiContextDto>.SuccessResponse(
            result,
            "AI context retrieved successfully."));
    }

    [HttpPatch("{userId:guid}")]
    public async Task<ActionResult<ApiResponse<InternalAiContextDto>>> Patch(
        Guid userId,
        [FromBody] InternalPatchAiContextDto patch,
        CancellationToken cancellationToken)
    {
        var result = await _service.PatchAsync(userId, patch, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalAiContextDto>.FailureResponse(
                $"User {userId} not found."));
        }

        return Ok(ApiResponse<InternalAiContextDto>.SuccessResponse(result, "AI context updated."));
    }

    [HttpPost("{userId:guid}/consume-ai-quota")]
    public async Task<ActionResult<ApiResponse<InternalAiQuotaResultDto>>> ConsumeAiQuota(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.TryConsumeAiQuotaAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalAiQuotaResultDto>.FailureResponse(
                $"User {userId} not found."));
        }

        if (!result.Allowed)
        {
            return StatusCode(
                StatusCodes.Status429TooManyRequests,
                new ApiResponse<InternalAiQuotaResultDto>
                {
                    Success = false,
                    Message = "Monthly AI quota exceeded.",
                    Data = result,
                });
        }

        return Ok(ApiResponse<InternalAiQuotaResultDto>.SuccessResponse(
            result,
            "AI quota consumed."));
    }
}
