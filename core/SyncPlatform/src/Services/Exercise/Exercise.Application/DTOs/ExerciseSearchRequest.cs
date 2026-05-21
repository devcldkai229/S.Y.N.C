namespace Exercise.Application.DTOs;

public class ExerciseSearchRequest
{
    public string? Query { get; set; }
    public string? Category { get; set; }
    public string? Difficulty { get; set; }
    public string? BodyRegion { get; set; }
    public string? MovementPattern { get; set; }
    public string? PrimaryMuscle { get; set; }
    public string? Equipment { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
