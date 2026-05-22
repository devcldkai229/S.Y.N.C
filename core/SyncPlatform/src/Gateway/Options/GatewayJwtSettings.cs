namespace Gateway.API.Options;

/// <summary>
/// JWT validation settings — must match the values configured in Iam.API (same Issuer/Audience/SecretKey).
/// The gateway only validates tokens; it never issues them.
/// </summary>
public class GatewayJwtSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    /// <summary>HMAC-SHA256 signing key shared with the IAM service (at least 32 bytes).</summary>
    public string SecretKey { get; set; } = string.Empty;
}
