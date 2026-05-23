using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace Libs.Auth.Context;

public class CurrentUserContext : ICurrentUserContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserContext(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    private ClaimsPrincipal? User => _httpContextAccessor.HttpContext?.User;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated == true;

    public Guid? UserId
    {
        get
        {
            if (User is null) return null;
            // Standard .NET ClaimTypes mapping; JWT 'sub' is the fallback when claim-mapping
            // is disabled or the token was issued with raw JWT claim names.
            var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
            return Guid.TryParse(sub, out var id) ? id : null;
        }
    }

    public string? Email =>
        User?.FindFirstValue(ClaimTypes.Email) ?? User?.FindFirstValue(JwtRegisteredClaimNames.Email);

    public string? Role =>
        User?.FindFirstValue(ClaimTypes.Role) ?? User?.FindFirstValue("role");

    public Guid RequireUserId()
    {
        var id = UserId;
        if (id is null || id == Guid.Empty)
            throw new UnauthorizedAccessException(
                "User identity is required but the request is not authenticated.");
        return id.Value;
    }
}
