using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IAuthService
{
    Task<RegisterResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<RegisterResponse> ResendVerificationAsync(ResendVerificationRequest request, CancellationToken cancellationToken = default);
    Task<VerifyEmailResponse> VerifyEmailAsync(string token, CancellationToken cancellationToken = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
    Task LogoutAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default);
}
