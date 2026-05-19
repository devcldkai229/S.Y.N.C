using Libs.Shared.Common;

namespace Iam.Domain.Models;

public class Achievement : BaseAuditableEntity
{
    public Achievement()
    {
        UserAchievements = new HashSet<UserAchievement>();
    }

    public string Code { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int XPReward { get; set; }

    public int CoinReward { get; set; }

    public string IconUrl { get; set; } = string.Empty;

    public string? RequirementJson { get; set; } = string.Empty;

    public virtual ICollection<UserAchievement> UserAchievements { get; set; }
}
