using Iam.Domain.Models;

namespace Iam.Application.Abstractions;

public interface IJwtTokenService
{
    /// <summary>Issue a signed JWT access token for the given user.</summary>
    (string Token, int ExpiresInSeconds) GenerateAccessToken(User user);

    /// <summary>Generate a cryptographically secure random refresh token (raw, unhashed).</summary>
    string GenerateRefreshToken();
}
