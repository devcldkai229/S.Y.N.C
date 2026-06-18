using System.Globalization;
using System.Text;

namespace Exercise.ImportTool.Services;

public static class StringSanitizer
{
    public static string Sanitize(string? value)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;

        var sb = new StringBuilder(value.Length);
        foreach (var c in value)
        {
            if (c is '\r' or '\n' or '\t') continue;
            if (c < ' ') continue;
            if (c is '\u200B' or '\uFEFF' or '\u200C' or '\u200D' or '\u2060') continue;

            var category = CharUnicodeInfo.GetUnicodeCategory(c);
            if (category is UnicodeCategory.Control or UnicodeCategory.Format) continue;

            sb.Append(c);
        }

        return sb.ToString().Trim();
    }

    public static List<string> SanitizeList(IEnumerable<string>? items)
    {
        if (items == null) return [];

        return items
            .Select(Sanitize)
            .Where(s => s.Length > 0)
            .ToList();
    }

    public static List<string> SplitAndSanitizeInstructions(IEnumerable<string>? instructions)
    {
        if (instructions == null) return [];

        var lines = new List<string>();
        foreach (var item in instructions)
        {
            if (string.IsNullOrWhiteSpace(item)) continue;

            var parts = item.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0)
            {
                var single = Sanitize(item);
                if (single.Length > 0) lines.Add(single);
                continue;
            }

            foreach (var part in parts)
            {
                var sanitized = Sanitize(part);
                if (sanitized.Length > 0) lines.Add(sanitized);
            }
        }

        return lines;
    }

    public static void SanitizeCatalog(Exercise.Domain.Models.ExerciseCatalog exercise)
    {
        exercise.ExerciseCode = Sanitize(exercise.ExerciseCode);
        exercise.NameEn = Sanitize(exercise.NameEn);
        exercise.NameVi = Sanitize(exercise.NameVi);
        exercise.Slug = Sanitize(exercise.Slug);
        exercise.ForceType = Sanitize(exercise.ForceType);
        exercise.MechanicType = Sanitize(exercise.MechanicType);
        exercise.SafetyLevel = Sanitize(exercise.SafetyLevel);
        exercise.PrimaryMuscles = SanitizeList(exercise.PrimaryMuscles);
        exercise.SecondaryMuscles = SanitizeList(exercise.SecondaryMuscles);
        exercise.EquipmentRequired = SanitizeList(exercise.EquipmentRequired);
        exercise.Contraindications = SanitizeList(exercise.Contraindications);
        exercise.RecommendedGoals = SanitizeList(exercise.RecommendedGoals);
        exercise.MovementTags = SanitizeList(exercise.MovementTags);
        exercise.AiCoachingCues = SanitizeList(exercise.AiCoachingCues);
        exercise.CommonMistakes = SanitizeList(exercise.CommonMistakes);
    }
}
