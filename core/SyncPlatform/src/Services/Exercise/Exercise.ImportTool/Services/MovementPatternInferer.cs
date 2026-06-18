using Exercise.ImportTool.Models;
using Libs.Shared.Enums;

namespace Exercise.ImportTool.Services;

public static class MovementPatternInferer
{
    public static MovementPattern Infer(FreeExerciseDbEntry source, ExerciseCategory category, BodyRegion bodyRegion)
    {
        var name = source.Name.ToLowerInvariant();
        var muscles = string.Join(' ', source.PrimaryMuscles).ToLowerInvariant();
        var force = source.Force?.Trim().ToLowerInvariant() ?? string.Empty;

        if (category == ExerciseCategory.Flexibility)
            return MovementPattern.General;

        if (category == ExerciseCategory.Cardio)
            return MovementPattern.General;

        if (name.Contains("squat") || name.Contains("lunge") || muscles.Contains("quadriceps"))
            return MovementPattern.Squat;

        if (name.Contains("deadlift") || name.Contains("hinge") || muscles.Contains("hamstrings"))
            return MovementPattern.Hinge;

        if (muscles.Contains("abdominals") || name.Contains("plank") || name.Contains("crunch") ||
            name.Contains("sit-up") || name.Contains("sit up"))
            return MovementPattern.Core;

        if (force == "static")
            return MovementPattern.Core;

        if (force == "pull")
        {
            if (name.Contains("pull-up") || name.Contains("chin-up") || name.Contains("lat") ||
                name.Contains("pulldown") || name.Contains("pull down"))
                return MovementPattern.VerticalPull;

            if (name.Contains("row") || muscles.Contains("middle back") || muscles.Contains("lats"))
                return MovementPattern.HorizontalPull;

            if (name.Contains("curl") || muscles is "biceps" or "forearms" ||
                muscles.Contains("biceps") || muscles.Contains("forearms"))
                return MovementPattern.General;

            return MovementPattern.General;
        }

        if (force == "push")
        {
            if (name.Contains("overhead") || name.Contains("shoulder press") ||
                (name.Contains("press") && muscles.Contains("shoulders")))
                return MovementPattern.VerticalPush;

            if (name.Contains("press") || name.Contains("push-up") || name.Contains("pushup") ||
                muscles.Contains("chest"))
                return MovementPattern.HorizontalPush;

            return MovementPattern.HorizontalPush;
        }

        if (name.Contains("pull-up") || name.Contains("chin-up"))
            return MovementPattern.VerticalPull;

        if (name.Contains("row"))
            return MovementPattern.HorizontalPull;

        if (name.Contains("press") && muscles.Contains("shoulders"))
            return MovementPattern.VerticalPush;

        if (name.Contains("press") || name.Contains("push-up"))
            return MovementPattern.HorizontalPush;

        if (bodyRegion == BodyRegion.Core)
            return MovementPattern.Core;

        return MovementPattern.General;
    }

    public static MovementPattern InferFromCatalog(Exercise.Domain.Models.ExerciseCatalog exercise)
    {
        var source = new FreeExerciseDbEntry
        {
            Name = exercise.NameEn,
            Force = string.IsNullOrWhiteSpace(exercise.ForceType) ? null : exercise.ForceType,
            PrimaryMuscles = exercise.PrimaryMuscles,
        };

        return Infer(source, exercise.Category, exercise.BodyRegion);
    }
}
