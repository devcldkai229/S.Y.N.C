using Exercise.Domain.Models;
using Libs.Shared.Enums;

namespace Exercise.ImportTool.Services;

public static class MovementTagBuilder
{
    public static List<string> Build(ExerciseCatalog exercise)
    {
        var tags = new List<string>();

        var force = exercise.ForceType.Trim().ToLowerInvariant();
        if (force is "push" or "pull" or "static")
            tags.Add(force);

        var mechanic = exercise.MechanicType.Trim().ToLowerInvariant();
        if (mechanic is "compound" or "isolation")
            tags.Add(mechanic);

        switch (exercise.BodyRegion)
        {
            case BodyRegion.UpperBody:
                tags.Add("upper");
                break;
            case BodyRegion.LowerBody:
                tags.Add("lower");
                break;
            case BodyRegion.Core:
                tags.Add("core");
                break;
            case BodyRegion.FullBody:
                tags.Add("full-body");
                break;
        }

        switch (exercise.Category)
        {
            case ExerciseCategory.Cardio:
                tags.Add("cardio");
                break;
            case ExerciseCategory.Flexibility:
                tags.Add("flexibility");
                break;
            case ExerciseCategory.Strength:
                tags.Add("strength");
                break;
        }

        return tags
            .Where(t => t.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(6)
            .ToList();
    }
}
