using Libs.Shared.Common;

namespace Iam.Domain.Models;

/// <summary>
/// Snapshot trình độ Adaptive Engine (consistency / progression / recovery) theo thời điểm.
/// </summary>
public class UserLevelSnapshot : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public DateTime ComputedAt { get; set; }

    /// <summary>0–100 tổng hợp từ consistency/progression/recovery/experience.</summary>
    public decimal LevelScore { get; set; }

    /// <summary>Beginner | Intermediate | Advanced</summary>
    public string Tier { get; set; } = "Beginner";

    public decimal ConsistencyScore { get; set; }

    public decimal ProgressionScore { get; set; }

    public decimal RecoveryCapacityScore { get; set; }

    /// <summary>Volume load (sets×reps×kg) tuần gần nhất; 0 nếu chưa có dữ liệu.</summary>
    public decimal VolumeLoadWeekly { get; set; }
}
