using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using Social.Domain.Repositories;

namespace Social.Application.Helpers;

public static partial class BlogSlugGenerator
{
    private const int MaxSlugLength = 80;
    private const int MaxAllocationAttempts = 12;

    public static string Slugify(string title)
    {
        if (string.IsNullOrWhiteSpace(title))
            return "post";

        var normalized = title.Trim().ToLowerInvariant().Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(normalized.Length);

        foreach (var ch in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(ch);
            if (category == UnicodeCategory.NonSpacingMark)
                continue;

            builder.Append(ch);
        }

        var ascii = builder.ToString().Normalize(NormalizationForm.FormC);
        ascii = ascii.Replace('đ', 'd').Replace('Đ', 'd');
        ascii = NonAlphanumericRegex().Replace(ascii, " ");
        ascii = WhitespaceRegex().Replace(ascii, "-").Trim('-');

        if (ascii.Length > MaxSlugLength)
            ascii = ascii[..MaxSlugLength].TrimEnd('-');

        return string.IsNullOrWhiteSpace(ascii) ? "post" : ascii;
    }

    public static async Task<string> AssignUniqueSlugAsync(
        IBlogRepository blogs,
        string title,
        Guid? excludeBlogId = null,
        CancellationToken cancellationToken = default)
    {
        var baseSlug = Slugify(title);

        if (!await blogs.SlugExistsAsync(baseSlug, excludeBlogId, cancellationToken))
            return baseSlug;

        for (var attempt = 0; attempt < MaxAllocationAttempts; attempt++)
        {
            var suffix = Random.Shared.Next(1000, 9999);
            var candidate = $"{baseSlug}-{suffix}";
            if (!await blogs.SlugExistsAsync(candidate, excludeBlogId, cancellationToken))
                return candidate;
        }

        return $"{baseSlug}-{Guid.NewGuid():N}"[..Math.Min(MaxSlugLength + 33, 100)];
    }

    [GeneratedRegex(@"[^a-z0-9\s-]", RegexOptions.CultureInvariant)]
    private static partial Regex NonAlphanumericRegex();

    [GeneratedRegex(@"\s+")]
    private static partial Regex WhitespaceRegex();
}
