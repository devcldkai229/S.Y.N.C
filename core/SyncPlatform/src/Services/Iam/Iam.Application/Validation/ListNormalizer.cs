namespace Iam.Application.Validation;

internal static class ListNormalizer
{
    public static List<string> NormalizeStrings(IEnumerable<string>? values) =>
        values?
            .Select(v => v.Trim())
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList() ?? [];
}
