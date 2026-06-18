using System.Text.Json;
using Libs.Seed;
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
        var json = File.ReadAllText(path);
        var doc = JsonDocument.Parse(json);

        if (!doc.RootElement.TryGetProperty("kitchens", out _))
            throw new InvalidOperationException("Seed file must contain a 'kitchens' array.");

        var seed = JsonSerializer.Deserialize<MarketplaceSeedFile>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to deserialize seed file.");

        if (seed.Kitchens.Count == 0)
            throw new InvalidOperationException("Seed file contains no kitchens.");

        EnrichImageQueries(seed);
        return seed;
    }

    private static string ResolveDefaultPath()
    {
        foreach (var fileName in new[] { "marketplace_final_final_final.json", "marketplace_seed_data.json" })
        {
            try
            {
                return SeedFileLocator.Resolve(fileName);
            }
            catch (FileNotFoundException)
            {
                // try next
            }
        }

        return SeedFileLocator.Resolve("marketplace_seed_data.json");
    }

    private static void EnrichImageQueries(MarketplaceSeedFile seed)
    {
        foreach (var kitchen in seed.Kitchens)
        {
            if (string.IsNullOrWhiteSpace(kitchen.LogoImageQuery))
                kitchen.LogoImageQuery = $"{kitchen.Name} restaurant logo";

            if (string.IsNullOrWhiteSpace(kitchen.CoverImageQuery))
                kitchen.CoverImageQuery = $"{kitchen.Type} restaurant food interior";

            foreach (var dish in kitchen.Menu)
            {
                if (string.IsNullOrWhiteSpace(dish.ImageQuery))
                    dish.ImageQuery = $"{dish.NameEn} {dish.Category} food dish";

                if (string.IsNullOrWhiteSpace(dish.S3Key))
                    dish.S3Key = $"food_catalog/{kitchen.Slug}/{dish.Slug}.webp";
            }
        }
    }
}
