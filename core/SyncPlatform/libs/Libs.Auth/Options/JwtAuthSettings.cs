namespace Libs.Auth.Options;

/// <summary>
/// JWT configuration shared by every Sync service.
/// All four required validation fields (Issuer, Audience, SecretKey) must match the IAM service.
/// AccessTokenExpiryMinutes and RefreshTokenExpiryDays are only used by IAM for token issuance —
/// other services ignore them.
/// </summary>
public class JwtAuthSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;

    /// <summary>HMAC-SHA256 signing key (must be at least 32 bytes / 256 bits).</summary>
    public string SecretKey { get; set; } = string.Empty;

    /// <summary>IAM-only: how long an access token stays valid before refresh is required.</summary>
    public int AccessTokenExpiryMinutes { get; set; } = 60;

    /// <summary>IAM-only: how long the device's refresh token remains valid.</summary>
    public int RefreshTokenExpiryDays { get; set; } = 30;
}
