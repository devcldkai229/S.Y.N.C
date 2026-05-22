using System.Security.Claims;
using Yarp.ReverseProxy.Transforms;
using Yarp.ReverseProxy.Transforms.Builder;

namespace Gateway.API.Transforms;

/// <summary>
/// Applied to every YARP route automatically.
/// When a request carries a validated JWT, the proven user identity is forwarded
/// to downstream services as trusted internal headers — so services never need to
/// re-parse the JWT themselves.
///
/// Header contract (internal only — strip at the ingress if exposed externally):
///   X-User-Id    = sub claim (Guid string)
///   X-User-Email = email claim
///   X-User-Role  = role claim
///   X-Request-Id = per-request correlation id (always set)
/// </summary>
public sealed class UserClaimsTransformProvider : ITransformProvider
{
    // ITransformProvider is called once per route at startup to register transforms.
    // The actual execution happens per-request inside AddRequestTransform.

    public void ValidateRoute(TransformRouteValidationContext context) { }
    public void ValidateCluster(TransformClusterValidationContext context) { }

    public void Apply(TransformBuilderContext transformContext)
    {
        transformContext.AddRequestTransform(ctx =>
        {
            var headers = ctx.ProxyRequest.Headers;

            // ── Always inject a correlation ID ───────────────────────────────
            var correlationId = ctx.HttpContext.TraceIdentifier;
            headers.TryAddWithoutValidation("X-Request-Id", correlationId);

            // ── Forward user identity from validated JWT claims ──────────────
            var user = ctx.HttpContext.User;
            if (user.Identity?.IsAuthenticated != true)
                return ValueTask.CompletedTask;

            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            var email  = user.FindFirstValue(ClaimTypes.Email);
            var role   = user.FindFirstValue(ClaimTypes.Role);

            if (userId is not null)
                headers.TryAddWithoutValidation("X-User-Id", userId);

            if (email is not null)
                // URI-encode to prevent header injection via unusual email chars
                headers.TryAddWithoutValidation("X-User-Email", Uri.EscapeDataString(email));

            if (role is not null)
                headers.TryAddWithoutValidation("X-User-Role", role);

            return ValueTask.CompletedTask;
        });
    }
}
