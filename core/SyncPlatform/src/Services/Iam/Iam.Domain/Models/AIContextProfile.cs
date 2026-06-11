using Libs.Shared.Common;

namespace Iam.Domain.Models;

/// <summary>
/// Bối cảnh hành vi cho agent — điểm số rủi ro / tuân thủ; cập nhật từ pipeline EDA hoặc batch ML.
/// </summary>
public class AIContextProfile : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public decimal AdherenceScore { get; set; }

    public decimal BurnoutRiskScore { get; set; }

    public decimal ChurnRiskScore { get; set; }

    public decimal MotivationScore { get; set; }

    public decimal RecoveryScore { get; set; }

    public decimal NutritionComplianceScore { get; set; }

    public decimal WorkoutComplianceScore { get; set; }

    public string? PeakEnergyTimeWindow { get; set; }

    public string? PreferredInterventionStyle { get; set; }

    public DateTimeOffset? LastBurnoutDetectedAt { get; set; }

    public DateTimeOffset? LastWorkoutSkippedAt { get; set; }

    public DateTimeOffset? LastCheatMealAt { get; set; }

    public string? CurrentMood { get; set; }

    public decimal AIConfidenceScore { get; set; }

    public DateTimeOffset? LastReplanAt { get; set; }
}
