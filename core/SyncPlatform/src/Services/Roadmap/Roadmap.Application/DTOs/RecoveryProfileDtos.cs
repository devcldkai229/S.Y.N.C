namespace Roadmap.Application.DTOs;

public class RecoveryProfileDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int CurrentRecoveryScore { get; set; }
    public int FatigueLevel { get; set; }
    public int MuscleSorenessScore { get; set; }
    public int CnsFatigueScore { get; set; }
    public string RecommendedTrainingIntensity { get; set; } = string.Empty;
    public int RecommendedWorkoutDuration { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreateRecoveryProfileDto
{
    public Guid UserId { get; set; }
    public int CurrentRecoveryScore { get; set; }
    public int FatigueLevel { get; set; }
    public int MuscleSorenessScore { get; set; }
    public int CnsFatigueScore { get; set; }
    public string RecommendedTrainingIntensity { get; set; } = string.Empty;
    public int RecommendedWorkoutDuration { get; set; }
}

public class UpdateRecoveryProfileDto
{
    public int CurrentRecoveryScore { get; set; }
    public int FatigueLevel { get; set; }
    public int MuscleSorenessScore { get; set; }
    public int CnsFatigueScore { get; set; }
    public string RecommendedTrainingIntensity { get; set; } = string.Empty;
    public int RecommendedWorkoutDuration { get; set; }
}
