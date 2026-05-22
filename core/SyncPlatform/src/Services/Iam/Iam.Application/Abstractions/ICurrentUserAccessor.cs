namespace Iam.Application.Abstractions;

/// <summary>
/// Resolves the authenticated user id for the current HTTP request.
/// MVP: reads <c>X-User-Id</c> header until JWT auth is wired.
/// </summary>
public interface ICurrentUserAccessor
{
    Guid GetRequiredUserId();
}
