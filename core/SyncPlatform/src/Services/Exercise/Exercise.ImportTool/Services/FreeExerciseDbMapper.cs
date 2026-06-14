using Exercise.Domain.Models;

using Exercise.ImportTool.Models;

using Libs.Shared.Enums;



namespace Exercise.ImportTool.Services;



public sealed class FreeExerciseDbMapper

{

    public ExerciseCatalog MapCatalog(FreeExerciseDbEntry source)

    {

        var entry = FreeExerciseDbEntrySanitizer.Sanitize(source);

        var category = MapCategory(entry.Category);

        var bodyRegion = InferBodyRegion(entry.PrimaryMuscles);

        var met = EstimateMet(entry.Category);

        var slug = Slugify(entry.Id);

        var forceType = entry.Force?.ToLowerInvariant() ?? string.Empty;

        var mechanicType = entry.Mechanic?.ToLowerInvariant() ?? string.Empty;



        return new ExerciseCatalog

        {

            ExerciseCode = entry.Id,

            NameEn = entry.Name,

            NameVi = entry.Name,

            Slug = slug,

            Category = category,

            Difficulty = MapDifficulty(entry.Level),

            MovementPattern = MovementPatternInferer.Infer(entry, category, bodyRegion),

            PrimaryMuscles = entry.PrimaryMuscles.ToList(),

            SecondaryMuscles = entry.SecondaryMuscles.ToList(),

            EquipmentRequired = string.IsNullOrWhiteSpace(entry.Equipment) ? [] : [entry.Equipment],

            IsCompound = string.Equals(mechanicType, "compound", StringComparison.OrdinalIgnoreCase),

            ForceType = forceType,

            MechanicType = mechanicType,

            BodyRegion = bodyRegion,

            MetValue = met,

            EstimatedCaloriesPerMinute = (int)Math.Round(met * 1.2m),

            RecommendedRestSeconds = MapRestSeconds(entry.Level),

            Contraindications = [],

            RecommendedGoals = [],

            MovementTags = MovementTagBuilder.Build(new ExerciseCatalog

            {

                ForceType = forceType,

                MechanicType = mechanicType,

                BodyRegion = bodyRegion,

                Category = category,

            }),

            AiCoachingCues = entry.Instructions.ToList(),

            CommonMistakes = [],

            RequiresSpotter = InferRequiresSpotter(entry),

            IsActive = true,

        };

    }



    public static string Slugify(string id) =>

        StringSanitizer.Sanitize(id).ToLowerInvariant().Replace('_', '-');



    private static ExerciseCategory MapCategory(string category) => category.Trim().ToLowerInvariant() switch

    {

        "cardio" => ExerciseCategory.Cardio,

        "stretching" => ExerciseCategory.Flexibility,

        "plyometrics" => ExerciseCategory.Cardio,

        "strength" or "powerlifting" or "strongman" or "olympic_weightlifting" => ExerciseCategory.Strength,

        _ => ExerciseCategory.Strength,

    };



    private static Difficulty MapDifficulty(string level) => level.Trim().ToLowerInvariant() switch

    {

        "beginner" => Difficulty.Beginner,

        "intermediate" => Difficulty.Intermediate,

        "expert" or "advanced" => Difficulty.Advanced,

        _ => Difficulty.Beginner,

    };



    private static int MapRestSeconds(string level) => level.Trim().ToLowerInvariant() switch

    {

        "intermediate" => 75,

        "expert" or "advanced" => 90,

        _ => 60,

    };



    private static decimal EstimateMet(string category) => category.Trim().ToLowerInvariant() switch

    {

        "cardio" => 7.5m,

        "stretching" => 2.5m,

        "plyometrics" => 8m,

        _ => 5m,

    };



    private static BodyRegion InferBodyRegion(IReadOnlyList<string> primaryMuscles)

    {

        if (primaryMuscles.Count == 0) return BodyRegion.FullBody;



        var upper = 0;

        var lower = 0;

        var core = 0;



        foreach (var muscle in primaryMuscles)

        {

            var m = muscle.ToLowerInvariant();

            if (m is "chest" or "shoulders" or "biceps" or "triceps" or "forearms" or "lats" or "middle back" or "traps")

                upper++;

            else if (m is "quadriceps" or "hamstrings" or "glutes" or "calves" or "adductors" or "abductors")

                lower++;

            else if (m is "abdominals" or "lower back")

                core++;

        }



        if (core > 0 && upper == 0 && lower == 0) return BodyRegion.Core;

        if (upper > 0 && lower > 0) return BodyRegion.FullBody;

        if (lower > 0) return BodyRegion.LowerBody;

        if (upper > 0) return BodyRegion.UpperBody;

        return BodyRegion.FullBody;

    }



    private static bool InferRequiresSpotter(FreeExerciseDbEntry source)

    {

        var equipment = source.Equipment?.ToLowerInvariant() ?? string.Empty;

        var name = source.Name.ToLowerInvariant();

        return equipment.Contains("barbell") &&

               (name.Contains("bench") || name.Contains("squat"));

    }

}


