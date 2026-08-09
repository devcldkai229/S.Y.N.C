using Libs.Shared.Common;

namespace Iam.Domain.Models;

/// <summary>
/// Audit mọi lần Adaptive Engine đổi mục tiêu calo/macro — giải trình + rollback.
/// </summary>
public class TargetAdjustmentLog : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    /// <summary>WeighIn | Weekly | Plateau | ProfileChange | Recovery</summary>
    public string Trigger { get; set; } = "WeighIn";

    public int? PrevCalories { get; set; }
    public int NewCalories { get; set; }

    public int? PrevProteinGram { get; set; }
    public int? PrevCarbGram { get; set; }
    public int? PrevFatGram { get; set; }
    public int NewProteinGram { get; set; }
    public int NewCarbGram { get; set; }
    public int NewFatGram { get; set; }

    public int EstimatedTdee { get; set; }
    public int FormulaTdee { get; set; }

    /// <summary>cao | trung bình | thấp (theo confidence engine)</summary>
    public string ConfidenceLevel { get; set; } = "thấp";

    public string ReasonCode { get; set; } = string.Empty;

    public string? ReasonText { get; set; }

    /// <summary>Auto | Confirmed</summary>
    public string AppliedMode { get; set; } = "Confirmed";

    public bool RoadmapChanged { get; set; }
}
