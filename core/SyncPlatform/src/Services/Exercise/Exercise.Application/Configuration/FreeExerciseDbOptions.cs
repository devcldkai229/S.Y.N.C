namespace Exercise.Application.Configuration;

public class FreeExerciseDbOptions
{
    public const string SectionName = "FreeExerciseDb";

    public string JsonUrl { get; set; } =
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json";

    public string ImageBaseUrl { get; set; } =
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/";
}
