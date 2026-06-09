using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Libs.Auth.Constants;
using Yarp.ReverseProxy.Transforms;
using Yarp.ReverseProxy.Transforms.Builder;

namespace Gateway.API.Transforms;

/// <summary>
/// Injects correlation and user identity headers after gateway JWT validation.
/// Downstream services must authorize via <c>HttpContext.User</c> (Bearer re-validated), not these headers.
/// </summary>
public sealed class UserClaimsTransformProvider : ITransformProvider
{
    public void ValidateRoute(TransformRouteValidationContext context) { }
    public void ValidateCluster(TransformClusterValidationContext context) { }

    public void Apply(TransformBuilderContext transformContext)
    {
        transformContext.AddRequestTransform(ctx =>
        {
            var headers = ctx.ProxyRequest.Headers;

            headers.TryAddWithoutValidation(AuthHeaders.RequestId, ctx.HttpContext.TraceIdentifier);

            var user = ctx.HttpContext.User;
            if (user.Identity?.IsAuthenticated != true)
                return ValueTask.CompletedTask;

            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier)
                         ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub);
            var email = user.FindFirstValue(ClaimTypes.Email)
                        ?? user.FindFirstValue(JwtRegisteredClaimNames.Email);
            var role = user.FindFirstValue(ClaimTypes.Role) ?? user.FindFirstValue("role");

            if (userId is not null)
                headers.TryAddWithoutValidation(AuthHeaders.UserId, userId);

            if (email is not null)
                headers.TryAddWithoutValidation(AuthHeaders.UserEmail, Uri.EscapeDataString(email));

            if (role is not null)
                headers.TryAddWithoutValidation(AuthHeaders.UserRole, role);

            return ValueTask.CompletedTask;
        });
    }
}
