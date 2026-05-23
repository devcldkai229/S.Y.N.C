namespace Libs.Auth.Constants;

/// <summary>
/// Internal-only headers that the API Gateway (YARP) injects after validating the JWT.
/// Downstream services may read these for logging/metrics, but should NEVER trust them
/// for authorization — always derive identity from <c>HttpContext.User</c> after
/// service-level JWT validation (defense in depth).
/// </summary>
public static class AuthHeaders
{
    public const string UserId    = "X-User-Id";
    public const string UserEmail = "X-User-Email";
    public const string UserRole  = "X-User-Role";
    public const string RequestId = "X-Request-Id";
}
