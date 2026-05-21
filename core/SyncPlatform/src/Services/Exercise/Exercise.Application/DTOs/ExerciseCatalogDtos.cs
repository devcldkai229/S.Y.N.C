using Libs.Shared.Enums;

namespace Exercise.Application.DTOs;

public class ExerciseCatalogDto
{
    public Guid Id { get; set; }
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
    public bool IsCompound { get; set; }
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
    public bool IsActive { get; set; }
}

public class CreateExerciseCatalogDto
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
    public bool IsCompound { get; set; }
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
}

public class UpdateExerciseCatalogDto : CreateExerciseCatalogDto
{
    public bool IsActive { get; set; }
}
