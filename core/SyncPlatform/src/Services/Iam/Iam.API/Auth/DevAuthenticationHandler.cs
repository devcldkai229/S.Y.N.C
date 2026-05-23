using System.Security.Claims;
using System.Text.Encodings.Web;
using Iam.API.Auth;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Iam.API.Auth;

/// <summary>
/// Development-only authentication: trusts <see cref="HeaderCurrentUserAccessor.UserIdHeaderName"/>.
/// </summary>
public sealed class DevAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "DevUserId";

    public DevAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(HeaderCurrentUserAccessor.UserIdHeaderName, out var values))
            return Task.FromResult(AuthenticateResult.Fail($"Missing header '{HeaderCurrentUserAccessor.UserIdHeaderName}'."));

        var raw = values.FirstOrDefault();
        if (!Guid.TryParse(raw, out var userId))
            return Task.FromResult(AuthenticateResult.Fail("Invalid user id header."));

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Name, userId.ToString())
        };

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
