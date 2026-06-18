using System.Security.Claims;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// POST /api/v1/auth/register — Create account + send verification email (SMTP when enabled).
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
    /// POST /api/v1/auth/init-registration — Send verification code (email + full name only, no password yet).
    /// </summary>
    [HttpPost("init-registration")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> InitRegistration(
        [FromBody] InitRegistrationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.InitRegistrationAsync(request, cancellationToken);
        var status = result.Message.Contains("sent", StringComparison.OrdinalIgnoreCase)
            ? StatusCodes.Status200OK
            : StatusCodes.Status201Created;
        return StatusCode(
            status,
            ApiResponse<RegisterResponse>.SuccessResponse(result, result.Message));
    }

    /// <summary>
    /// POST /api/v1/auth/complete-registration — Verify OTP; password is optional on this step.
    /// </summary>
    [HttpPost("complete-registration")]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<VerifyEmailResponse>>> CompleteRegistration(
        [FromBody] CompleteRegistrationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.CompleteRegistrationAsync(request, cancellationToken);
        return Ok(ApiResponse<VerifyEmailResponse>.SuccessResponse(result, "Email verified successfully."));
    }

    /// <summary>
    /// POST /api/v1/auth/finish-registration — Set password after email was verified without a password.
    /// </summary>
    [HttpPost("finish-registration")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> FinishRegistration(
        [FromBody] FinishRegistrationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.FinishRegistrationAsync(request, cancellationToken);
        return Ok(ApiResponse<RegisterResponse>.SuccessResponse(result, result.Message));
    }

    /// <summary>
    /// POST /api/v1/auth/resend-verification — Resend verification code for an existing unverified account.
    /// </summary>
    [HttpPost("resend-verification")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> ResendVerification(
        [FromBody] ResendVerificationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.ResendVerificationAsync(request, cancellationToken);
        return Ok(ApiResponse<RegisterResponse>.SuccessResponse(result, "Verification code resent."));
    }

    /// <summary>
    /// GET /api/v1/auth/verify-email?token=... — Activate the account (opened from email button in browser).
    /// Returns a simple HTML page for humans; JSON clients can send Accept: application/json.
    /// </summary>
    [HttpGet("verify-email")]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> VerifyEmail(
        [FromQuery] string token,
        CancellationToken cancellationToken)
    {
        var wantsJson = Request.Headers.Accept.Any(h =>
            h?.Contains("application/json", StringComparison.OrdinalIgnoreCase) == true);

        try
        {
            var result = await _authService.VerifyEmailAsync(token, cancellationToken);

            if (wantsJson)
                return Ok(ApiResponse<VerifyEmailResponse>.SuccessResponse(result, "Email verified successfully."));

            var html = VerificationEmailTemplate.BuildVerifyResultHtml(
                success: true,
                title: "Email đã được xác nhận",
                message: $"Tài khoản {result.Email} đã kích hoạt. Bạn có thể đóng trang này và đăng nhập trên app.");
            return Content(html, "text/html; charset=utf-8");
        }
        catch (BadRequestException ex)
        {
            if (wantsJson)
                return BadRequest(ApiResponse<object>.FailureResponse(ex.Message));
            return new ContentResult
            {
                Content = VerificationEmailTemplate.BuildVerifyResultHtml(false, "Không thể xác nhận", ex.Message),
                ContentType = "text/html; charset=utf-8",
                StatusCode = StatusCodes.Status400BadRequest
            };
        }
        catch (NotFoundException ex)
        {
            if (wantsJson)
                return NotFound(ApiResponse<object>.FailureResponse(ex.Message));
            return new ContentResult
            {
                Content = VerificationEmailTemplate.BuildVerifyResultHtml(false, "Link không hợp lệ", ex.Message),
                ContentType = "text/html; charset=utf-8",
                StatusCode = StatusCodes.Status404NotFound
            };
        }
    }

    /// <summary>
    /// POST /api/v1/auth/forgot-password — Send a 6-digit reset code to the account email.
    /// Always returns 200 with a generic message (does not reveal whether the email exists).
    /// </summary>
    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ApiResponse<ForgotPasswordResponse>>> ForgotPassword(
        [FromBody] ForgotPasswordRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.ForgotPasswordAsync(request, cancellationToken);
        return Ok(ApiResponse<ForgotPasswordResponse>.SuccessResponse(result, result.Message));
    }

    /// <summary>
    /// POST /api/v1/auth/reset-password — Set a new password using the emailed reset code.
    /// </summary>
    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(ApiResponse<ResetPasswordResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ApiResponse<ResetPasswordResponse>>> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _authService.ResetPasswordAsync(request, cancellationToken);
        return Ok(ApiResponse<ResetPasswordResponse>.SuccessResponse(result, result.Message));
    }

    /// <summary>
    /// POST /api/v1/auth/login — Issue an access + refresh token pair for the given device.
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
    /// POST /api/v1/auth/google — Sign in / sign up using a Google ID token from the Flutter SDK.
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
    /// POST /api/v1/auth/refresh — Rotate refresh token + issue a new access token.
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
    /// POST /api/v1/auth/logout — Revoke the refresh token for the current device. Requires Bearer auth.
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
