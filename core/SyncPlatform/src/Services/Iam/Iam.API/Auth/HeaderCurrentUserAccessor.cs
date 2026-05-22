using Iam.Application.Abstractions;
using Iam.Application.Common;

namespace Iam.API.Auth;

/// <summary>
/// MVP auth: pass the authenticated user id via <c>X-User-Id</c> request header.
/// </summary>
public sealed class HeaderCurrentUserAccessor : ICurrentUserAccessor
{
    public const string UserIdHeaderName = "X-User-Id";
    private readonly IHttpContextAccessor _httpContextAccessor;

    public HeaderCurrentUserAccessor(IHttpContextAccessor httpContextAccessor) =>
        _httpContextAccessor = httpContextAccessor;

    public Guid GetRequiredUserId()
    {
        var context = _httpContextAccessor.HttpContext
            ?? throw new AppValidationException("HTTP context is not available.");

        if (!context.Request.Headers.TryGetValue(UserIdHeaderName, out var rawValues))
            throw new AppValidationException($"Missing required header '{UserIdHeaderName}'.");

        var raw = rawValues.FirstOrDefault();
        if (!Guid.TryParse(raw, out var userId))
            throw new AppValidationException($"'{UserIdHeaderName}' must be a valid GUID.");

        return userId;
    }
}
