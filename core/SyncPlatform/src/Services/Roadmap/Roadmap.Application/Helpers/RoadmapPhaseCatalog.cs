using Roadmap.Application.DTOs;

namespace Roadmap.Application.Helpers;

/// <summary>
/// Hardcoded 3-phase catalog (hướng B): Foundation → Build → Peak.
/// Week ranges are split evenly across total weeks.
/// </summary>
public static class RoadmapPhaseCatalog
{
    public const string Foundation = "foundation";
    public const string Build = "build";
    public const string Peak = "peak";

    public static string NormalizeGoal(string? fitnessGoal)
    {
        var g = (fitnessGoal ?? string.Empty).Trim();
        if (g.Equals("LoseFat", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("FatLoss", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("WeightLoss", StringComparison.OrdinalIgnoreCase))
            return "FatLoss";
        if (g.Equals("BuildMuscle", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("MuscleGain", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("Hypertrophy", StringComparison.OrdinalIgnoreCase))
            return "MuscleGain";
        if (g.Equals("GeneralHealth", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("Maintain", StringComparison.OrdinalIgnoreCase) ||
            g.Equals("Maintenance", StringComparison.OrdinalIgnoreCase))
            return "GeneralHealth";
        return string.IsNullOrEmpty(g) ? "GeneralHealth" : g;
    }

    public static string NormalizeExperience(string? experienceLevel)
    {
        var e = (experienceLevel ?? string.Empty).Trim();
        if (e.Equals("Intermediate", StringComparison.OrdinalIgnoreCase))
            return "Intermediate";
        if (e.Equals("Advanced", StringComparison.OrdinalIgnoreCase) ||
            e.Equals("Expert", StringComparison.OrdinalIgnoreCase))
            return "Advanced";
        return "Beginner";
    }

    /// <summary>Map free-form CurrentPhase string to catalog key.</summary>
    public static string ResolveCurrentPhaseKey(string? currentPhase)
    {
        var p = (currentPhase ?? string.Empty).Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(p))
            return Foundation;

        if (p.Contains("foundation") || p.Contains("nền tảng") || p.Contains("base") || p == "1")
            return Foundation;
        if (p.Contains("hypertrophy") || p.Contains("build") || p.Contains("tăng cường") ||
            p.Contains("strength") || p == "2")
            return Build;
        if (p.Contains("peak") || p.Contains("bứt phá") || p.Contains("cut") ||
            p.Contains("maintenance") || p == "3")
            return Peak;

        // Unknown label: treat as foundation so UI still shows a current phase.
        return Foundation;
    }

    public static int ComputeTotalWeeks(DateTimeOffset startDate, DateTimeOffset? expectedEndDate)
    {
        var end = expectedEndDate ?? startDate.AddDays(12 * 7);
        var days = Math.Max(1, (end.Date - startDate.Date).TotalDays + 1);
        var weeks = (int)Math.Ceiling(days / 7.0);
        return Math.Clamp(weeks, 1, 104);
    }

    public static int ComputeCurrentWeek(DateTimeOffset startDate, DateTimeOffset? expectedEndDate, DateTimeOffset now)
    {
        var total = ComputeTotalWeeks(startDate, expectedEndDate);
        var elapsedDays = Math.Max(0, (now.Date - startDate.Date).TotalDays);
        var week = (int)Math.Floor(elapsedDays / 7.0) + 1;
        return Math.Clamp(week, 1, total);
    }

    public static IReadOnlyList<PhaseOverviewDto> BuildPhases(
        string? currentPhase,
        int totalWeeks)
    {
        totalWeeks = Math.Max(1, totalWeeks);
        var w1End = Math.Max(1, totalWeeks / 3);
        var w2End = Math.Max(w1End + 1, (2 * totalWeeks) / 3);
        if (w2End > totalWeeks)
            w2End = totalWeeks;
        if (w1End >= w2End && totalWeeks >= 2)
            w1End = Math.Max(1, w2End - 1);

        var currentKey = ResolveCurrentPhaseKey(currentPhase);
        var keys = new[] { Foundation, Build, Peak };
        var ranges = new[]
        {
            (From: 1, To: w1End),
            (From: Math.Min(w1End + 1, totalWeeks), To: w2End),
            (From: Math.Min(w2End + 1, totalWeeks), To: totalWeeks),
        };

        var currentIndex = Array.IndexOf(keys, currentKey);
        if (currentIndex < 0) currentIndex = 0;

        var result = new List<PhaseOverviewDto>(3);
        for (var i = 0; i < 3; i++)
        {
            var status = i < currentIndex ? "Done" : i == currentIndex ? "Current" : "Upcoming";
            var (nameVi, nameEn) = DisplayNames(keys[i]);
            result.Add(new PhaseOverviewDto
            {
                Key = keys[i],
                DisplayNameVi = nameVi,
                DisplayNameEn = nameEn,
                Status = status,
                WeekFrom = ranges[i].From,
                WeekTo = ranges[i].To,
            });
        }

        return result;
    }

    public static int PhasePercent(IReadOnlyList<PhaseOverviewDto> phases, int currentWeek)
    {
        var current = phases.FirstOrDefault(p => p.Status == "Current") ?? phases.FirstOrDefault();
        if (current is null) return 0;
        var span = Math.Max(1, current.WeekTo - current.WeekFrom + 1);
        var into = Math.Clamp(currentWeek - current.WeekFrom + 1, 0, span);
        return (int)Math.Round(100.0 * into / span);
    }

    private static (string Vi, string En) DisplayNames(string key) => key switch
    {
        Foundation => ("Nền tảng", "Foundation"),
        Build => ("Tăng cường", "Build"),
        Peak => ("Bứt phá", "Peak"),
        _ => ("Nền tảng", "Foundation"),
    };
}
