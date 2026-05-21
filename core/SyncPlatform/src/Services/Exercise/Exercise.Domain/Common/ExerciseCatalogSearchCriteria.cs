using Libs.Shared.Enums;

namespace Exercise.Domain.Common;

public class ExerciseCatalogSearchCriteria
{
    public string? Query { get; set; }
    public ExerciseCategory? Category { get; set; }
    public Difficulty? Difficulty { get; set; }
    public BodyRegion? BodyRegion { get; set; }
    public MovementPattern? MovementPattern { get; set; }
    public string? PrimaryMuscle { get; set; }
    public string? Equipment { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
