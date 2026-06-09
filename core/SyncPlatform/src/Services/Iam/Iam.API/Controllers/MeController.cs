using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1/me")]
public class MeController : ControllerBase
{
    private readonly UserMeService _userMeService;

    public MeController(UserMeService userMeService)
    {
        _userMeService = userMeService;
    }

    /// <summary>
    /// GET /api/v1/me/profile-settings — Account, fitness profile, and AI preferences.
    /// </summary>
    [HttpGet("profile-settings")]
    [ProducesResponseType(typeof(ApiResponse<ProfileSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ProfileSettingsResponse>>> GetProfileSettings(
        CancellationToken cancellationToken)
    {
        var result = await _userMeService.GetProfileSettingsAsync(cancellationToken);
        return Ok(ApiResponse<ProfileSettingsResponse>.SuccessResponse(
            result,
            "Profile settings retrieved successfully."));
    }

    /// <summary>
    /// GET /api/v1/me/inventory — Vouchers and unlocked achievements.
    /// </summary>
    [HttpGet("inventory")]
    [ProducesResponseType(typeof(ApiResponse<InventoryResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<InventoryResponse>>> GetInventory(
        CancellationToken cancellationToken)
    {
        var result = await _userMeService.GetInventoryAsync(cancellationToken);
        return Ok(ApiResponse<InventoryResponse>.SuccessResponse(
            result,
            "Inventory retrieved successfully."));
    }

    /// <summary>
    /// PUT /api/v1/me/basic-profile — Update display account fields.
    /// </summary>
    [HttpPut("basic-profile")]
    [ProducesResponseType(typeof(ApiResponse<ProfileSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ProfileSettingsResponse>>> UpdateBasicProfile(
        [FromBody] UpdateBasicProfileRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _userMeService.UpdateBasicProfileAsync(request, cancellationToken);
        return Ok(ApiResponse<ProfileSettingsResponse>.SuccessResponse(
            result,
            "Basic profile updated successfully."));
    }

    /// <summary>
    /// PUT /api/v1/me/fitness-profile — Create or update biometric / fitness profile.
    /// </summary>
    [HttpPut("fitness-profile")]
    [ProducesResponseType(typeof(ApiResponse<ProfileSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ProfileSettingsResponse>>> UpdateFitnessProfile(
        [FromBody] UpdateFitnessProfileRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _userMeService.UpdateFitnessProfileAsync(request, cancellationToken);
        return Ok(ApiResponse<ProfileSettingsResponse>.SuccessResponse(
            result,
            "Fitness profile updated successfully."));
    }

    /// <summary>
    /// PUT /api/v1/me/account-preferences — AI persona, nutrition prefs, and consents.
    /// </summary>
    [HttpPut("account-preferences")]
    [ProducesResponseType(typeof(ApiResponse<ProfileSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<ProfileSettingsResponse>>> UpdateAccountPreferences(
        [FromBody] UpdateAccountPreferencesRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _userMeService.UpdateAccountPreferencesAsync(request, cancellationToken);
        return Ok(ApiResponse<ProfileSettingsResponse>.SuccessResponse(
            result,
            "Account preferences updated successfully."));
    }
}
