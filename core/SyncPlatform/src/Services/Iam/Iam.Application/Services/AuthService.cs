using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Application.Options;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.Extensions.Options;

namespace Iam.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly IUserDeviceRepository _deviceRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _tokenService;
    private readonly IGoogleTokenValidator _googleValidator;
    private readonly IEmailSender _emailSender;
    private readonly JwtSettings _jwtSettings;

    public AuthService(
        IUserRepository userRepository,
        IUserDeviceRepository deviceRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenService tokenService,
        IGoogleTokenValidator googleValidator,
        IEmailSender emailSender,
        IOptions<JwtSettings> jwtOptions)
    {
        _userRepository = userRepository;
        _deviceRepository = deviceRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _googleValidator = googleValidator;
        _emailSender = emailSender;
        _jwtSettings = jwtOptions.Value;
    }

    // ── 1. Register ──────────────────────────────────────────────────────────

    public async Task<RegisterResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        if (await _userRepository.EmailExistsAsync(normalizedEmail, cancellationToken))
            throw new ConflictException($"An account with email '{normalizedEmail}' already exists.");

        var verificationToken = Guid.NewGuid().ToString("N");

        var user = new User
        {
            Email = normalizedEmail,
            PasswordHash = _passwordHasher.Hash(request.Password),
            FullName = request.FullName,
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
            Email = user.Email
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
        var googleInfo = await _googleValidator.ValidateAsync(request.IdToken, cancellationToken);

        var normalizedEmail = googleInfo.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken);

        if (user is null)
        {
            user = new User
            {
                Email = normalizedEmail,
                PasswordHash = string.Empty, // Google-only account — no local password
                FullName = googleInfo.Name,
                AvatarUrl = googleInfo.Picture,
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
            throw new ForbiddenException("This account is no longer active.");
        }
        else if (!user.EmailVerified)
        {
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
}
