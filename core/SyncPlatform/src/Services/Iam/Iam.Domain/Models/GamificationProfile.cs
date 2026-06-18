using Libs.Shared.Common;

namespace Iam.Domain.Models;

public class GamificationProfile : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public int CurrentLevel { get; set; }

    public long CurrentXP { get; set; }

    public int CurrentStreak { get; set; }

    public int LongestStreak { get; set; }

    public decimal SyncCoins { get; set; }

    public long AchievementPoints { get; set; }

    public int ConsecutivePerfectDays { get; set; }

    /// <summary>UTC date of the last time the user logged an activity. Used to calculate streaks.</summary>
    public DateTimeOffset? LastActivityDate { get; set; }
}
