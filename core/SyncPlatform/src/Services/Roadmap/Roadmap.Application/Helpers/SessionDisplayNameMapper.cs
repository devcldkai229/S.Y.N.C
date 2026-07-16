namespace Roadmap.Application.Helpers;

public static class SessionDisplayNameMapper
{
    public static string ToDisplayNameVi(string sessionTitle, string sessionType)
    {
        var haystack = $"{sessionTitle} {sessionType}".Trim();
        if (string.IsNullOrWhiteSpace(haystack))
            return "Buổi tập";

        var lower = haystack.ToLowerInvariant();

        if (ContainsAny(lower, "lower", "leg", "chân", "thân dưới"))
            return "Sức mạnh thân dưới";
        if (ContainsAny(lower, "push"))
            return "Đẩy thân trên";
        if (ContainsAny(lower, "pull"))
            return "Kéo thân trên";
        if (ContainsAny(lower, "upper", "thân trên"))
            return "Thân trên";
        if (ContainsAny(lower, "full body", "toàn thân", "fullbody"))
            return "Toàn thân";
        if (ContainsAny(lower, "hiit"))
            return "Cardio cường độ cao";
        if (ContainsAny(lower, "cardio"))
            return "Cardio nhẹ";
        if (ContainsAny(lower, "mobility", "stretch", "vận động"))
            return "Vận động và phục hồi";
        if (ContainsAny(lower, "recovery", "rest", "phục hồi"))
            return "Phục hồi chủ động";
        if (ContainsAny(lower, "strength", "sức mạnh"))
            return "Sức mạnh";

        return string.IsNullOrWhiteSpace(sessionTitle) ? sessionType : sessionTitle;
    }

    public static string IntensityFromEnergy(int energyDemandScore)
    {
        if (energyDemandScore <= 4) return "Light";
        if (energyDemandScore <= 7) return "Moderate";
        return "High";
    }

    private static bool ContainsAny(string haystack, params string[] needles) =>
        needles.Any(n => haystack.Contains(n, StringComparison.Ordinal));
}
