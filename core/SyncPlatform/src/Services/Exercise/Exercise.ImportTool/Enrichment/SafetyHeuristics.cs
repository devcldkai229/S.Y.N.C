using Exercise.Domain.Models;

namespace Exercise.ImportTool.Enrichment;

/// <summary>Deterministic safety rules — LLM must not set these.</summary>
public static class SafetyHeuristics
{
    public static string ResolveSafetyLevel(ExerciseCatalog exercise)
    {
        var name = exercise.NameEn.ToLowerInvariant();
        var equipment = string.Join(' ', exercise.EquipmentRequired).ToLowerInvariant();

        if (name.Contains("snatch") || name.Contains("clean and jerk") || name.Contains("clean & jerk") ||
            (equipment.Contains("barbell") && name.Contains("overhead")))
        {
            return "High";
        }

        if (equipment.Contains("barbell") && exercise.IsCompound &&
            (name.Contains("squat") || name.Contains("deadlift") || name.Contains("bench") || name.Contains("press")))
        {
            return "Caution";
        }

        if (equipment is "" or "body only" or "bodyweight" ||
            exercise.Category == Libs.Shared.Enums.ExerciseCategory.Flexibility)
        {
            return "Safe";
        }

        if (equipment.Contains("machine") || equipment.Contains("cable"))
        {
            return "Moderate";
        }

        return exercise.IsCompound ? "Caution" : "Moderate";
    }

    public static bool ResolveRequiresSpotter(ExerciseCatalog exercise)
    {
        var name = exercise.NameEn.ToLowerInvariant();
        var equipment = string.Join(' ', exercise.EquipmentRequired).ToLowerInvariant();

        if (!equipment.Contains("barbell")) return false;

        if (name.Contains("bench press") || name.Contains("barbell bench")) return true;
        if (name.Contains("squat") && name.Contains("barbell")) return true;
        if (name.Contains("overhead press") || name.Contains("military press") || name.Contains("shoulder press"))
            return true;

        return false;
    }
}
