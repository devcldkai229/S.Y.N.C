using Exercise.Domain.Models;
using Libs.Shared.Enums;

namespace Exercise.ImportTool.Enrichment;

/// <summary>Deterministic MET estimates — LLM must not set these.</summary>
public static class MetTable
{
    public static decimal ResolveMetValue(ExerciseCatalog exercise)
    {
        var name = exercise.NameEn.ToLowerInvariant();
        var equipment = string.Join(' ', exercise.EquipmentRequired).ToLowerInvariant();

        if (name.Contains("snatch") || name.Contains("clean and jerk") || name.Contains("clean & jerk"))
            return 6.0m;

        if (equipment.Contains("barbell") && (name.Contains("squat") || name.Contains("deadlift") || name.Contains("bench")))
            return exercise.IsCompound ? 6.0m : 5.0m;

        return exercise.Category switch
        {
            ExerciseCategory.Flexibility => 2.3m,
            ExerciseCategory.Mobility => 2.5m,
            ExerciseCategory.Cardio => 7.5m,
            ExerciseCategory.Strength => exercise.IsCompound ? 5.0m : 3.8m,
            _ => exercise.IsCompound ? 5.0m : 3.8m,
        };
    }

    public static int EstimatedCaloriesPerMinute(decimal metValue) =>
        (int)Math.Round(metValue * 1.225m, MidpointRounding.AwayFromZero);
}
