using Libs.Shared.Enums;

namespace Exercise.Domain.Models;

public class ExerciseCatalog : BaseMongoEntity
{
    public string ExerciseCode { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string NameVi { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public ExerciseCategory Category { get; set; }

    public Difficulty Difficulty { get; set; }

    public MovementPattern MovementPattern { get; set; }

    public List<string> PrimaryMuscles { get; set; } = [];

    public List<string> SecondaryMuscles { get; set; } = [];

    public List<string> EquipmentRequired { get; set; } = [];

    public string ExerciseType { get; set; } = string.Empty;

    public string ForceType { get; set; } = string.Empty;

    public string MechanicType { get; set; } = string.Empty;

    public BodyRegion BodyRegion { get; set; }

    public int EstimatedCaloriesPerMinute { get; set; }

    public decimal MetValue { get; set; }

    public int RecommendedRestSeconds { get; set; }

    public List<string> Contraindications { get; set; } = [];

    public List<string> RecommendedGoals { get; set; } = [];

    public List<string> MovementTags { get; set; } = [];

    public List<string> AiCoachingCues { get; set; } = [];

    public List<string> CommonMistakes { get; set; } = [];

    public string SafetyLevel { get; set; } = string.Empty;

    public bool RequiresSpotter { get; set; }

    public bool IsAiRecommended { get; set; }

    public bool IsActive { get; set; }
}
