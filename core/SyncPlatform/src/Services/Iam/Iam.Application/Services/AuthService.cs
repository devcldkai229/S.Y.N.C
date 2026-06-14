using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Helpers;
using Iam.Application.Options;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Libs.Auth.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Cryptography;

namespace Iam.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly IUserDeviceRepository _deviceRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _tokenService;
    private readonly IGoogleTokenValidator _googleValidator;
    private readonly IEmailSender _emailSender;
    private readonly JwtAuthSettings _jwtSettings;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository userRepository,
        IUserDeviceRepository deviceRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenService tokenService,
        IGoogleTokenValidator googleValidator,
        IEmailSender emailSender,
        IOptions<JwtAuthSettings> jwtOptions,
        ILogger<AuthService> logger)
    {
        _userRepository = userRepository;
        _deviceRepository = deviceRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _googleValidator = googleValidator;
        _emailSender = emailSender;
        _jwtSettings = jwtOptions.Value;
        _logger = logger;
    }

    // ── 1. Register ──────────────────────────────────────────────────────────

    public async Task<RegisterResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        if (await _userRepository.EmailExistsAsync(normalizedEmail, cancellationToken))
            throw new ConflictException($"An account with email '{normalizedEmail}' already exists.");

        var verificationToken = await GenerateUniqueVerificationCodeAsync(cancellationToken);

        var user = new User
        {
            Email = normalizedEmail,
            PasswordHash = _passwordHasher.Hash(request.Password),
            FullName = request.FullName,
            AvatarUrl = RandomAvatarUrl.ForRegistration(normalizedEmail, request.FullName),
            Role = UserRole.User,
            Status = UserStatus.PendingVerification,
            SubscriptionTier = SubscriptionTier.Free,
            EmailVerified = false,
            EmailVerificationToken = verificationToken,
            PreferredLanguage = "vi",
            TimeZone = "Asia/Ho_Chi_Minh"
        };

        await _userRepository.AddAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);

        await _emailSender.SendVerificationEmailAsync(user.Email, verificationToken, cancellationToken);

        return new RegisterResponse
        {
            UserId = user.Id,
            Email = user.Email,
            Message = "Registration successful. Please check your email for the verification code."
        };
    }

    public async Task<RegisterResponse> InitRegistrationAsync(InitRegistrationRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var existing = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken);

        if (existing is not null)
        {
            if (existing.EmailVerified)
                throw new ConflictException($"An account with email '{normalizedEmail}' already exists.");

            var verificationToken = await GenerateUniqueVerificationCodeAsync(cancellationToken);
            existing.FullName = request.FullName.Trim();
            existing.EmailVerificationToken = verificationToken;
            if (string.IsNullOrWhiteSpace(existing.AvatarUrl))
                existing.AvatarUrl = RandomAvatarUrl.ForRegistration(normalizedEmail, existing.FullName);
            existing.UpdatedAt = DateTimeOffset.UtcNow;
            await _userRepository.SaveChangesAsync(cancellationToken);
            await _emailSender.SendVerificationEmailAsync(existing.Email, verificationToken, cancellationToken);

            return new RegisterResponse
            {
                UserId = existing.Id,
                Email = existing.Email,
                Message = "A verification code has been sent to your email."
            };
        }

        var code = await GenerateUniqueVerificationCodeAsync(cancellationToken);
        var user = new User
        {
            Email = normalizedEmail,
            PasswordHash = string.Empty,
            FullName = request.FullName.Trim(),
            AvatarUrl = RandomAvatarUrl.ForRegistration(normalizedEmail, request.FullName),
            Role = UserRole.User,
            Status = UserStatus.PendingVerification,
            SubscriptionTier = SubscriptionTier.Free,
            EmailVerified = false,
            EmailVerificationToken = code,
            PreferredLanguage = "vi",
            TimeZone = "Asia/Ho_Chi_Minh"
        };

        await _userRepository.AddAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);
        await _emailSender.SendVerificationEmailAsync(user.Email, code, cancellationToken);

        return new RegisterResponse
        {
            UserId = user.Id,
            Email = user.Email,
            Message = "A verification code has been sent to your email."
        };
    }

    public async Task<VerifyEmailResponse> CompleteRegistrationAsync(
        CompleteRegistrationRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var code = request.Code.Trim();

        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken)
            ?? throw new NotFoundException("Invalid or expired verification code.");

        if (string.IsNullOrEmpty(user.EmailVerificationToken)
            || !string.Equals(user.EmailVerificationToken, code, StringComparison.Ordinal))
        {
            throw new NotFoundException("Invalid or expired verification code.");
        }

        user.EmailVerified = true;
        user.EmailVerificationToken = null;
        user.Status = UserStatus.Active;
        user.UpdatedAt = DateTimeOffset.UtcNow;

        if (!string.IsNullOrWhiteSpace(request.Password))
            user.PasswordHash = _passwordHasher.Hash(request.Password);

        if (string.IsNullOrWhiteSpace(user.AvatarUrl))
            user.AvatarUrl = RandomAvatarUrl.ForRegistration(user.Email, user.FullName);

        await _userRepository.SaveChangesAsync(cancellationToken);

        return new VerifyEmailResponse
        {
            UserId = user.Id,
            Email = user.Email,
            EmailVerified = true
        };
    }

    public async Task<RegisterResponse> FinishRegistrationAsync(
        FinishRegistrationRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken)
            ?? throw new NotFoundException($"No account found with email '{normalizedEmail}'.");

        if (!user.EmailVerified)
            throw new BadRequestException("Email has not been verified yet.");

        if (!string.IsNullOrEmpty(user.PasswordHash))
            throw new ConflictException("Password has already been set for this account.");

        user.PasswordHash = _passwordHasher.Hash(request.Password);
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        return new RegisterResponse
        {
            UserId = user.Id,
            Email = user.Email,
            Message = "Registration completed. You can now sign in."
        };
    }

    public async Task<RegisterResponse> ResendVerificationAsync(ResendVerificationRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken)
            ?? throw new NotFoundException($"No account found with email '{normalizedEmail}'.");

        if (user.EmailVerified)
            throw new ConflictException("Email is already verified. Please login.");

        var verificationToken = await GenerateUniqueVerificationCodeAsync(cancellationToken);
        user.EmailVerificationToken = verificationToken;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        await _emailSender.SendVerificationEmailAsync(user.Email, verificationToken, cancellationToken);

        return new RegisterResponse
        {
            UserId = user.Id,
            Email = user.Email,
            Message = "A new verification code has been sent to your email."
        };
    }

    // ── 2. Verify email ──────────────────────────────────────────────────────

    public async Task<VerifyEmailResponse> VerifyEmailAsync(string token, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new BadRequestException("Verification token is required.");

        var user = await _userRepository.GetByEmailVerificationTokenAsync(token, cancellationToken)
            ?? throw new NotFoundException("Invalid or expired verification token.");

        user.EmailVerified = true;
        user.EmailVerificationToken = null;
        user.Status = UserStatus.Active;
        user.UpdatedAt = DateTimeOffset.UtcNow;

        await _userRepository.SaveChangesAsync(cancellationToken);

        return new VerifyEmailResponse
        {
            UserId = user.Id,
            Email = user.Email,
            EmailVerified = true
        };
    }

    // ── 2b. Forgot / reset password ──────────────────────────────────────────

    public async Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken);

        // Always return a generic response to avoid leaking which emails are registered.
        var response = new ForgotPasswordResponse
        {
            Email = normalizedEmail,
            Message = "If an account exists for this email, a reset code has been sent."
        };

        // Only send a code to a usable local account.
        if (user is null
            || user.Status == UserStatus.Suspended
            || user.Status == UserStatus.Deleted
            || string.IsNullOrEmpty(user.PasswordHash))
        {
            return response;
        }

        var resetCode = GenerateResetCode();
        user.PasswordResetToken = resetCode;
        user.PasswordResetTokenExpiresAt = DateTimeOffset.UtcNow.AddMinutes(15);
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        await _emailSender.SendPasswordResetEmailAsync(user.Email, resetCode, cancellationToken);

        return response;
    }

    public async Task<ResetPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var code = request.Code.Trim();

        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken)
            ?? throw new BadRequestException("Invalid email or reset code.");

        if (string.IsNullOrEmpty(user.PasswordResetToken)
            || user.PasswordResetTokenExpiresAt is null)
        {
            throw new BadRequestException("No password reset was requested for this account.");
        }

        if (user.PasswordResetTokenExpiresAt <= DateTimeOffset.UtcNow)
            throw new BadRequestException("Reset code has expired. Please request a new one.");

        if (!string.Equals(user.PasswordResetToken, code, StringComparison.Ordinal))
            throw new BadRequestException("Invalid email or reset code.");

        user.PasswordHash = _passwordHasher.Hash(request.NewPassword);
        user.PasswordResetToken = null;
        user.PasswordResetTokenExpiresAt = null;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        return new ResetPasswordResponse
        {
            Email = user.Email,
            Message = "Password has been reset successfully. Please login with your new password."
        };
    }

    // ── 3. Login ─────────────────────────────────────────────────────────────

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken)
            ?? throw new UnauthorizedException("Invalid email or password.");

        if (user.Status == UserStatus.Suspended || user.Status == UserStatus.Deleted)
            throw new ForbiddenException("This account is no longer active.");

        if (!user.EmailVerified)
            throw new ForbiddenException("Email has not been verified.");

        if (string.IsNullOrEmpty(user.PasswordHash))
            throw new ForbiddenException("Please complete registration by setting a password.");

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedException("Invalid email or password.");

        var authResponse = await IssueTokensAsync(user, request.DeviceId, request.Platform, cancellationToken);

        user.LastLoginAt = DateTimeOffset.UtcNow;
        user.LastActiveAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        return authResponse;
    }

    // ── 4. Google login ──────────────────────────────────────────────────────

    public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Google sign-in attempt (device={DeviceId}, platform={Platform})",
            request.DeviceId, request.Platform);

        GoogleUserInfo googleInfo;
        try
        {
            googleInfo = await _googleValidator.ValidateAsync(request.IdToken, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Google token validation failed (device={DeviceId})", request.DeviceId);
            throw;
        }

        var normalizedEmail = googleInfo.Email.Trim().ToLowerInvariant();
        _logger.LogInformation("Google token valid for {Email} (sub={Subject})", normalizedEmail, googleInfo.Subject);

        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken);

        if (user is null)
        {
            _logger.LogInformation("Creating new user via Google sign-in: {Email}", normalizedEmail);
            user = new User
            {
                Email = normalizedEmail,
                PasswordHash = string.Empty, // Google-only account — no local password
                FullName = googleInfo.Name,
                AvatarUrl = !string.IsNullOrWhiteSpace(googleInfo.Picture)
                    ? googleInfo.Picture
                    : RandomAvatarUrl.ForRegistration(normalizedEmail, googleInfo.Name),
                Role = UserRole.User,
                Status = UserStatus.Active,
                SubscriptionTier = SubscriptionTier.Free,
                EmailVerified = true,
                PreferredLanguage = "vi",
                TimeZone = "Asia/Ho_Chi_Minh"
            };
            await _userRepository.AddAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);
        }
        else if (user.Status == UserStatus.Suspended || user.Status == UserStatus.Deleted)
        {
            _logger.LogWarning("Google sign-in blocked for inactive account {Email}", normalizedEmail);
            throw new ForbiddenException("This account is no longer active.");
        }
        else if (!user.EmailVerified)
        {
            _logger.LogInformation("Marking email verified via Google sign-in: {Email}", normalizedEmail);
            // First successful Google sign-in verifies the email (Google already vouches for it).
            user.EmailVerified = true;
            user.EmailVerificationToken = null;
            if (user.Status == UserStatus.PendingVerification)
                user.Status = UserStatus.Active;
        }

        var authResponse = await IssueTokensAsync(user, request.DeviceId, request.Platform, cancellationToken);

        user.LastLoginAt = DateTimeOffset.UtcNow;
        user.LastActiveAt = DateTimeOffset.UtcNow;
        await _userRepository.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Google sign-in successful for {Email} (userId={UserId})", normalizedEmail, user.Id);
        return authResponse;
    }

    // ── 5. Refresh (rotation) ────────────────────────────────────────────────

    public async Task<AuthResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        var device = await _deviceRepository.GetByDeviceIdAsync(request.DeviceId, cancellationToken)
            ?? throw new UnauthorizedException("Invalid refresh token.");

        if (device.IsRevoked
            || string.IsNullOrEmpty(device.RefreshTokenHash)
            || device.RefreshTokenExpiryTime is null
            || device.RefreshTokenExpiryTime <= DateTimeOffset.UtcNow)
        {
            throw new UnauthorizedException("Refresh token has expired or been revoked.");
        }

        if (!_passwordHasher.Verify(request.RefreshToken, device.RefreshTokenHash))
            throw new UnauthorizedException("Invalid refresh token.");

        var user = await _userRepository.GetByIdAsync(device.UserId, cancellationToken)
            ?? throw new UnauthorizedException("Invalid refresh token.");

        if (user.Status == UserStatus.Suspended || user.Status == UserStatus.Deleted)
            throw new ForbiddenException("This account is no longer active.");

        var (accessToken, expiresInSeconds) = _tokenService.GenerateAccessToken(user);
        var newRefreshToken = _tokenService.GenerateRefreshToken();

        device.RefreshTokenHash = _passwordHasher.Hash(newRefreshToken);
        device.RefreshTokenExpiryTime = DateTimeOffset.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);
        device.IsRevoked = false;
        device.LastSeenAt = DateTimeOffset.UtcNow;
        device.UpdatedAt = DateTimeOffset.UtcNow;
        _deviceRepository.Update(device);
        await _deviceRepository.SaveChangesAsync(cancellationToken);

        return new AuthResponse
        {
            UserId = user.Id,
            Email = user.Email,
            FullName = user.FullName,
            AccessToken = accessToken,
            RefreshToken = newRefreshToken,
            ExpiresIn = expiresInSeconds
        };
    }

    // ── 6. Logout ────────────────────────────────────────────────────────────

    public async Task LogoutAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            throw new UnauthorizedException("User is not authenticated.");
        if (string.IsNullOrWhiteSpace(deviceId))
            throw new BadRequestException("DeviceId is required.");

        var device = await _deviceRepository.GetByUserAndDeviceAsync(userId, deviceId, cancellationToken);
        if (device is null) return; // Idempotent: already logged out / never logged in on this device

        device.IsRevoked = true;
        device.RefreshTokenHash = null;
        device.RefreshTokenExpiryTime = null;
        device.UpdatedAt = DateTimeOffset.UtcNow;
        _deviceRepository.Update(device);
        await _deviceRepository.SaveChangesAsync(cancellationToken);
    }

    // ── Shared token issuance ────────────────────────────────────────────────

    private async Task<AuthResponse> IssueTokensAsync(
        User user,
        string deviceId,
        DevicePlatform platform,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(deviceId))
            throw new BadRequestException("DeviceId is required.");

        var (accessToken, expiresInSeconds) = _tokenService.GenerateAccessToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken();
        var refreshTokenHash = _passwordHasher.Hash(refreshToken);
        var refreshTokenExpiry = DateTimeOffset.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

        // Upsert device record (UserId + DeviceId is unique)
        var device = await _deviceRepository.GetByUserAndDeviceAsync(user.Id, deviceId, cancellationToken);
        if (device is null)
        {
            device = new UserDevice
            {
                UserId = user.Id,
                DeviceId = deviceId,
                Platform = platform,
                AppVersion = "unknown",
                LastSeenAt = DateTimeOffset.UtcNow,
                RefreshTokenHash = refreshTokenHash,
                RefreshTokenExpiryTime = refreshTokenExpiry,
                IsRevoked = false
            };
            await _deviceRepository.AddAsync(device, cancellationToken);
        }
        else
        {
            device.Platform = platform;
            device.LastSeenAt = DateTimeOffset.UtcNow;
            device.RefreshTokenHash = refreshTokenHash;
            device.RefreshTokenExpiryTime = refreshTokenExpiry;
            device.IsRevoked = false;
            device.UpdatedAt = DateTimeOffset.UtcNow;
            _deviceRepository.Update(device);
        }
        await _deviceRepository.SaveChangesAsync(cancellationToken);

        return new AuthResponse
        {
            UserId = user.Id,
            Email = user.Email,
            FullName = user.FullName,
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = expiresInSeconds
        };
    }

    private async Task<string> GenerateUniqueVerificationCodeAsync(CancellationToken cancellationToken)
    {
        // 6-digit code for in-app OTP-style verification.
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var number = RandomNumberGenerator.GetInt32(0, 1_000_000);
            var code = number.ToString("D6");
            var existing = await _userRepository.GetByEmailVerificationTokenAsync(code, cancellationToken);
            if (existing is null)
                return code;
        }

        // Fallback for extremely rare collisions.
        return Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
    }

    private static string GenerateResetCode()
    {
        // 6-digit OTP for password reset (looked up per-account, so no uniqueness needed).
        return RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
    }
}
