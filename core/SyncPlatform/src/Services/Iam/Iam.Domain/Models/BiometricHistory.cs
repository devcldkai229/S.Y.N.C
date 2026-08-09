using Libs.Shared.Common;

namespace Iam.Domain.Models;

/// <summary>
/// Chuỗi weigh-in theo thời gian — nền tảng của Adaptive Coaching Engine
/// (BiometricProfile chỉ giữ giá trị hiện tại nên không đối chiếu thực tế được).
/// </summary>
public class BiometricHistory : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    /// <summary>Thời điểm cân (UTC). Client gửi giờ local → API quy về UTC.</summary>
    public DateTime RecordedAtUtc { get; set; }

    public decimal WeightKg { get; set; }

    public decimal? BodyFatPercentage { get; set; }

    public decimal? MuscleMassKg { get; set; }

    /// <summary>Manual | Device | AiEstimated</summary>
    public string Source { get; set; } = "Manual";

    public string? Note { get; set; }
}
