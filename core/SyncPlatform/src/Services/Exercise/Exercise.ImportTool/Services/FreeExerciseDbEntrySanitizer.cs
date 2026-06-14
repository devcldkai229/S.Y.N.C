using Exercise.ImportTool.Models;

namespace Exercise.ImportTool.Services;

public static class FreeExerciseDbEntrySanitizer
{
    public static FreeExerciseDbEntry Sanitize(FreeExerciseDbEntry entry)
    {
        return new FreeExerciseDbEntry
        {
            Id = StringSanitizer.Sanitize(entry.Id),
            Name = StringSanitizer.Sanitize(entry.Name),
            Category = StringSanitizer.Sanitize(entry.Category),
            Level = StringSanitizer.Sanitize(entry.Level),
            Force = string.IsNullOrWhiteSpace(entry.Force) ? null : StringSanitizer.Sanitize(entry.Force),
            Mechanic = string.IsNullOrWhiteSpace(entry.Mechanic) ? null : StringSanitizer.Sanitize(entry.Mechanic),
            Equipment = string.IsNullOrWhiteSpace(entry.Equipment) ? null : StringSanitizer.Sanitize(entry.Equipment),
            PrimaryMuscles = StringSanitizer.SanitizeList(entry.PrimaryMuscles),
            SecondaryMuscles = StringSanitizer.SanitizeList(entry.SecondaryMuscles),
            Instructions = StringSanitizer.SplitAndSanitizeInstructions(entry.Instructions),
            Images = StringSanitizer.SanitizeList(entry.Images),
        };
    }
}
