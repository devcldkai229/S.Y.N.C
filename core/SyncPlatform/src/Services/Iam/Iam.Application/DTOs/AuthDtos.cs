using System.ComponentModel.DataAnnotations;
using Iam.Domain.Enums;

namespace Iam.Application.DTOs;

public class RegisterRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string Password { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string FullName { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string DeviceId { get; set; } = string.Empty;

    public DevicePlatform Platform { get; set; } = DevicePlatform.Web;
}

public class LoginRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(128)]
    public string Password { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string DeviceId { get; set; } = string.Empty;

    public DevicePlatform Platform { get; set; } = DevicePlatform.Web;
}

public class ResendVerificationRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;
}

/// <summary>Start registration with email verification only — password is set later.</summary>
public class InitRegistrationRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string FullName { get; set; } = string.Empty;
}

/// <summary>Verify email OTP; optionally set password in the same step.</summary>
public class CompleteRegistrationRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(64)]
    public string Code { get; set; } = string.Empty;

    [MinLength(8), MaxLength(128)]
    public string? Password { get; set; }
}

/// <summary>Set password after email was verified without a password.</summary>
public class FinishRegistrationRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string Password { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(64)]
    public string Code { get; set; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string NewPassword { get; set; } = string.Empty;
}

public class GoogleLoginRequest
{
    [Required]
    public string IdToken { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string DeviceId { get; set; } = string.Empty;

    public DevicePlatform Platform { get; set; } = DevicePlatform.Web;
}

public class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string DeviceId { get; set; } = string.Empty;
}

public class LogoutRequest
{
    [Required, MaxLength(256)]
    public string DeviceId { get; set; } = string.Empty;
}

public class AuthResponse
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    /// <summary>Access token lifetime in seconds.</summary>
    public int ExpiresIn { get; set; }
}

public class RegisterResponse
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = "Registration successful. Please check your email to verify your account.";
}

public class VerifyEmailResponse
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public bool EmailVerified { get; set; }
}

public class ForgotPasswordResponse
{
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = "If an account exists for this email, a reset code has been sent.";
}

public class ResetPasswordResponse
{
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = "Password has been reset successfully. Please login with your new password.";
}
