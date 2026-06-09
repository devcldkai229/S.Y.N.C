using Libs.Shared.Common;
using Iam.Domain.Enums;

namespace Iam.Domain.Models;

public class UserDevice : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public string DeviceId { get; set; } = string.Empty;

    public DevicePlatform Platform { get; set; }

    public string? PushToken { get; set; }

    public string AppVersion { get; set; } = string.Empty;

    public DateTimeOffset? LastSeenAt { get; set; }

    /// <summary>BCrypt hash of the refresh token issued for this device. Null = no active session.</summary>
    public string? RefreshTokenHash { get; set; }

    public DateTimeOffset? RefreshTokenExpiryTime { get; set; }

    /// <summary>Marks the session as invalidated (e.g. user logged out, password reset, suspicious activity).</summary>
    public bool IsRevoked { get; set; }
}
