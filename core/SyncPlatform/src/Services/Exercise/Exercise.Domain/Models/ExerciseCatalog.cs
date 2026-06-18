using Libs.Shared.Enums;
using MongoDB.Bson.Serialization.Attributes;

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

    // true = Compound (Đa khớp), false = Isolation (Cô lập)
    public bool IsCompound { get; set; }

    /// <summary>push | pull | static — from free-exercise-db force field.</summary>
    public string ForceType { get; set; } = string.Empty;

    /// <summary>compound | isolation — from free-exercise-db mechanic field.</summary>
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

    public bool RequiresSpotter { get; set; }

    /// <summary>Safe | Moderate | Caution | High — set by enrichment heuristics.</summary>
    public string SafetyLevel { get; set; } = "Moderate";

    /// <summary>AI-generated contraindications hidden from users until reviewed.</summary>
    public bool NeedsReview { get; set; }

    [BsonIgnoreIfNull]
    public DateTimeOffset? AiEnrichedAt { get; set; }

    public bool IsActive { get; set; } = true;

}
