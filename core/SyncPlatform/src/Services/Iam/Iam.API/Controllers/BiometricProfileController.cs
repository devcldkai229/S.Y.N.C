using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/v1/biometrics")]
public class BiometricProfileController : ControllerBase
{
    private readonly IBiometricProfileService _service;

    public BiometricProfileController(IBiometricProfileService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> GetProfile(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.GetProfileAsync(userId, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Biometric profile retrieved successfully."));
    }

    [HttpPost("onboarding/basic")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveBasicInfo(
        [FromBody] OnboardingStep1Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.SaveBasicInfoAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Basic info saved successfully."));
    }

    [HttpPost("onboarding/goals")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveGoals(
        [FromBody] OnboardingStep2Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.SaveGoalsAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Goals saved and calorie targets calculated successfully."));
    }

    [HttpPost("onboarding/composition")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveComposition(
        [FromBody] OnboardingStep3Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.SaveCompositionAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Body composition saved successfully."));
    }

    [HttpPost("onboarding/safeguards")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveSafeguards(
        [FromBody] OnboardingStep4Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.SaveSafeguardsAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Safety guardrails saved successfully."));
    }

    [HttpPatch("weight")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> LogWeight(
        [FromBody] UpdateWeightDto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _service.LogWeightAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Weight logged and calorie targets recalculated successfully."));
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                  ?? User.FindFirst("sub")?.Value;
        
        if (Guid.TryParse(sub, out var userIdFromClaim))
        {
            return userIdFromClaim;
        }

        if (Request.Headers.TryGetValue("X-User-Id", out var userIdHeader) && 
            Guid.TryParse(userIdHeader, out var userIdFromHeader))
        {
            return userIdFromHeader;
        }

        throw new UnauthorizedAccessException("User identification not found in request context.");
    }
}
