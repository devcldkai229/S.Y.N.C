namespace Libs.Auth.Constants;

public static class AuthPolicies
{
    /// <summary>Any authenticated user (valid JWT).</summary>
    public const string AuthenticatedUser = "AuthenticatedUser";

    /// <summary>Authenticated AND role == SystemAdmin.</summary>
    public const string AdminOnly = "AdminOnly";

    /// <summary>Authenticated AND role == Partner.</summary>
    public const string PartnerOnly = "PartnerOnly";
}
