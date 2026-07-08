namespace Iam.Application.DTOs;

/// <summary>Partial update of AIContextProfile from SYNC AI insight worker.</summary>
public class InternalPatchAiContextDto
{
    public decimal? AdherenceScore { get; set; }
    public decimal? BurnoutRiskScore { get; set; }
    public decimal? RecoveryScore { get; set; }
    public decimal? ChurnRiskScore { get; set; }
    public decimal? MotivationScore { get; set; }
    public string? CurrentMood { get; set; }
    public string? MoodNote { get; set; }
}
