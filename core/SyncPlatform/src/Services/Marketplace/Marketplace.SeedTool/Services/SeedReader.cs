using System.Text.Json;
using Marketplace.SeedTool.Models;

namespace Marketplace.SeedTool.Services;

public sealed class SeedReader
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    public MarketplaceSeedFile Read(string? path = null)
    {
        path ??= ResolveDefaultPath();

        if (!File.Exists(path))
            throw new FileNotFoundException($"Seed file not found: {path}");

        var json = File.ReadAllText(path);
        var doc = JsonDocument.Parse(json);

        if (!doc.RootElement.TryGetProperty("kitchens", out _))
            throw new InvalidOperationException("Seed file must contain a 'kitchens' array.");

        var seed = JsonSerializer.Deserialize<MarketplaceSeedFile>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to deserialize seed file.");

        if (seed.Kitchens.Count == 0)
            throw new InvalidOperationException("Seed file contains no kitchens.");

        return seed;
    }

    private static string ResolveDefaultPath()
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Seed", "marketplace_seed_data.json"),
            Path.Combine(AppContext.BaseDirectory, "marketplace_seed_data.json"),
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "Seed", "marketplace_seed_data.json")),
        };

        foreach (var candidate in candidates)
        {
            if (File.Exists(candidate))
                return candidate;
        }

        return candidates[0];
    }
}
