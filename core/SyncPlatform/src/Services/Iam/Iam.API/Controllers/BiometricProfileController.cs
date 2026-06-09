using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Services;
using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/biometrics")]
public class BiometricProfileController : ControllerBase
{
    private readonly IBiometricProfileService _service;
    private readonly ICurrentUserContext _currentUser;

    public BiometricProfileController(
        IBiometricProfileService service,
        ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> GetProfile(CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.GetProfileAsync(userId, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Biometric profile retrieved successfully."));
    }

    [HttpPost("onboarding/basic")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveBasicInfo(
        [FromBody] OnboardingStep1Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.SaveBasicInfoAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Basic info saved successfully."));
    }

    [HttpPost("onboarding/goals")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveGoals(
        [FromBody] OnboardingStep2Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.SaveGoalsAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Goals saved and calorie targets calculated successfully."));
    }

    [HttpPost("onboarding/composition")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveComposition(
        [FromBody] OnboardingStep3Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.SaveCompositionAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Body composition saved successfully."));
    }

    [HttpPost("onboarding/safeguards")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> SaveSafeguards(
        [FromBody] OnboardingStep4Dto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.SaveSafeguardsAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Safety guardrails saved successfully."));
    }

    [HttpPatch("weight")]
    public async Task<ActionResult<ApiResponse<BiometricProfileDto>>> LogWeight(
        [FromBody] UpdateWeightDto dto,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.LogWeightAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<BiometricProfileDto>.SuccessResponse(result, "Weight logged and calorie targets recalculated successfully."));
    }
}
