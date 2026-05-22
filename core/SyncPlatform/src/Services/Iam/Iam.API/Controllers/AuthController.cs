using System.Security.Claims;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// POST /api/auth/register — Create account + send verification email (token is logged to console for dev).
    /// </summary>
    [HttpPost("register")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.RegisterAsync(request, cancellationToken);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<RegisterResponse>.SuccessResponse(result, "Registration successful."));
    }

    /// <summary>
    /// GET /api/auth/verify-email?token=... — Activate the account using the token sent by email.
    /// </summary>
    [HttpGet("verify-email")]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<VerifyEmailResponse>>> VerifyEmail(
        [FromQuery] string token,
        CancellationToken cancellationToken)
    {
        var result = await _authService.VerifyEmailAsync(token, cancellationToken);
        return Ok(ApiResponse<VerifyEmailResponse>.SuccessResponse(result, "Email verified successfully."));
    }

    /// <summary>
    /// POST /api/auth/login — Issue an access + refresh token pair for the given device.
    /// </summary>
    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.LoginAsync(request, cancellationToken);
        return Ok(ApiResponse<AuthResponse>.SuccessResponse(result, "Login successful."));
    }

    /// <summary>
    /// POST /api/auth/google — Sign in / sign up using a Google ID token from the Flutter SDK.
    /// </summary>
    [HttpPost("google")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Google(
        [FromBody] GoogleLoginRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.GoogleLoginAsync(request, cancellationToken);
        return Ok(ApiResponse<AuthResponse>.SuccessResponse(result, "Google sign-in successful."));
    }

    /// <summary>
    /// POST /api/auth/refresh — Rotate refresh token + issue a new access token.
    /// </summary>
    [HttpPost("refresh")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Refresh(
        [FromBody] RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.RefreshAsync(request, cancellationToken);
        return Ok(ApiResponse<AuthResponse>.SuccessResponse(result, "Token refreshed successfully."));
    }

    /// <summary>
    /// POST /api/auth/logout — Revoke the refresh token for the current device. Requires Bearer auth.
    /// </summary>
    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<object?>>> Logout(
        [FromBody] LogoutRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        await _authService.LogoutAsync(userId, request.DeviceId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Logged out successfully."));
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");
        if (Guid.TryParse(sub, out var userId))
            return userId;
        throw new UnauthorizedException("Invalid or missing user identity claim.");
    }
}
