using Libs.Shared.Common;

namespace Iam.Domain.Models;

public class UserAchievement : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public Guid AchievementId { get; set; }

    public DateTimeOffset UnlockedAt { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual Achievement Achievement { get; set; } = null!;
}
