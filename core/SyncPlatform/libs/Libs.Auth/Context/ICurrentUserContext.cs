namespace Libs.Auth.Context;

/// <summary>
/// Accessor for the currently-authenticated user.
/// Always derived from the JWT's validated claims (NameIdentifier, Email, Role) —
/// never from request headers — to enforce defense in depth.
/// </summary>
public interface ICurrentUserContext
{
    bool   IsAuthenticated { get; }
    Guid?  UserId          { get; }
    string? Email          { get; }
    string? Role           { get; }

    /// <summary>Returns the user id or throws <see cref="UnauthorizedAccessException"/>.</summary>
    Guid RequireUserId();
}
