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
}
