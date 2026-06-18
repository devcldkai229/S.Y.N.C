namespace Libs.Seed;

public static class SeedFileLocator
{
    public static string Resolve(string fileName, string? explicitPath = null)
    {
        if (!string.IsNullOrWhiteSpace(explicitPath) && File.Exists(explicitPath))
            return Path.GetFullPath(explicitPath);

        var candidates = new List<string>
        {
            Path.Combine(AppContext.BaseDirectory, "Seed", fileName),
            Path.Combine(AppContext.BaseDirectory, fileName),
        };

        var dir = AppContext.BaseDirectory;
        for (var i = 0; i < 10; i++)
        {
            candidates.Add(Path.Combine(dir, fileName));
            candidates.Add(Path.Combine(dir, "..", fileName));
            var parent = Path.GetDirectoryName(dir);
            if (string.IsNullOrEmpty(parent) || parent == dir)
                break;
            dir = parent;
        }

        foreach (var path in candidates.Select(Path.GetFullPath).Distinct())
        {
            if (File.Exists(path))
                return path;
        }

        throw new FileNotFoundException(
            $"Seed file '{fileName}' not found. Searched: {string.Join(", ", candidates.Take(5))}...");
    }
}
