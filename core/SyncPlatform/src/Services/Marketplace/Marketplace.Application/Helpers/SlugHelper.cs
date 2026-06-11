using System.Text.RegularExpressions;

namespace Marketplace.Application.Helpers;

public static partial class SlugHelper
{
    public static string FromName(string name) =>
        SlugRegex().Replace(name.ToLowerInvariant().Trim(), "-").Trim('-');

    [GeneratedRegex(@"[^a-z0-9]+")]
    private static partial Regex SlugRegex();
}
