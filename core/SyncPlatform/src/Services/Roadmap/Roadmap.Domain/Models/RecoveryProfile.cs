using Roadmap.Domain.Models;

namespace Roadmap.Domain.Models;

public class RecoveryProfile : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public int CurrentRecoveryScore { get; set; }

    public int FatigueLevel { get; set; }

    public int SleepRecoveryScore { get; set; }

    public int MuscleSorenessScore { get; set; }

    public int CnsFatigueScore { get; set; }

    public string RecommendedTrainingIntensity { get; set; } = string.Empty;

    public int RecommendedWorkoutDuration { get; set; }
}
