namespace Iam.Application.DTOs;

/// <summary>
/// Bối cảnh tổng hợp cho SYNC AI Layer — gộp biometrics + AIContextProfile +
/// preference trong 1 call (giảm round-trip). Chỉ field cần cho coaching;
/// AI Layer tự de-identify thêm trước khi đưa vào prompt gửi cloud LLM.
/// Trả qua endpoint nội bộ /api/internal/ai-context/{userId}/full-context.
/// </summary>
public class InternalAiContextDto
{
    // Identity tối thiểu
    public Guid UserId { get; set; }
    public string PreferredLanguage { get; set; } = "vi";
    public string SubscriptionTier { get; set; } = "Free";

    /// <summary>Họ tên — dùng cho AI checkout contact (không đưa vào LLM prompt).</summary>
    public string? FullName { get; set; }

    /// <summary>SĐT — dùng cho AI checkout contact (không đưa vào LLM prompt).</summary>
    public string? PhoneNumber { get; set; }

    // Persona / motivation (UserPreference)
    public string AgentPersona { get; set; } = "FriendlyBuddy";
    public string MotivationStyle { get; set; } = "Supportive";
    public bool AutoOrderEnabled { get; set; }
    public decimal? MaxAutoOrderLimitPerOrder { get; set; }
    public decimal? MaxAutoOrderLimitDaily { get; set; }
    public List<string> Allergies { get; set; } = new();
    public List<string> DislikedFoods { get; set; } = new();

    // Biometrics / mục tiêu
    public string? FitnessGoal { get; set; }
    public string? ActivityLevel { get; set; }
    public string? ExperienceLevel { get; set; }
    public string? Gender { get; set; }
    public decimal? CurrentWeightKg { get; set; }
    public decimal? TargetWeightKg { get; set; }
    public decimal? HeightCm { get; set; }
    public decimal? CurrentBodyFatPercentage { get; set; }
    public decimal? GoalBodyFatPercentage { get; set; }
    public decimal? MuscleMassKg { get; set; }
    public string? WorkoutLocationPreference { get; set; }
    public int? BaseTDEE { get; set; }
    public int? Bmr { get; set; }
    public int? DailyProteinTargetGram { get; set; }
    public int? DailyCarbTargetGram { get; set; }
    public int? DailyFatTargetGram { get; set; }
    public int? DailyCalorieTarget { get; set; }
    public bool TargetsManagedByEngine { get; set; }
    /// <summary>Lần engine chỉnh targets gần nhất — dùng cap max 1 adjustment/tuần.</summary>
    public DateTime? TargetsAdjustedAtUtc { get; set; }
    public List<string> Injuries { get; set; } = new();
    public List<string> Medications { get; set; } = new();

    // AIContextProfile (điểm số cá nhân hoá)
    public decimal AdherenceScore { get; set; }
    public decimal BurnoutRiskScore { get; set; }
    public decimal RecoveryScore { get; set; }
    public decimal MotivationScore { get; set; }
    public string? CurrentMood { get; set; }
    public string? PeakEnergyTimeWindow { get; set; }
}
