using System.Text.Json;
using Libs.Seed;
using Social.SeedTool.Models;

namespace Social.SeedTool.Services;

public sealed class SocialSeedReader
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    public SocialSeedFile Read(string? combinedPath = null)
    {
        var file = SeedFileLocator.Resolve("social_seed_data.json", combinedPath);
        var json = File.ReadAllText(file);
        var combined = JsonSerializer.Deserialize<SocialSeedFile>(json, JsonOptions) ?? new SocialSeedFile();

        if (combined.Posts.Count > 0 && combined.Comments.Count > 0)
            return combined;

        if (combined.Posts.Count == 0)
            MergeFrom(SeedFileLocator.Resolve("social_posts_seed_data.json"), combined, f => f.Posts);

        if (combined.Comments.Count == 0)
            MergeFrom(SeedFileLocator.Resolve("social_comments_seed_data.json"), combined, f => f.Comments);

        if (combined.Interactions.Count == 0)
            MergeFrom(SeedFileLocator.Resolve("social_interactions_seed_data.json"), combined, f => f.Interactions);

        if (combined.UserFollows.Count == 0)
            MergeFrom(SeedFileLocator.Resolve("social_userFollows_seed_data.json"), combined, f => f.UserFollows);

        return combined;
    }

    private static void MergeFrom<T>(
        string path,
        SocialSeedFile target,
        Func<SocialSeedFile, List<T>> selector)
    {
        var json = File.ReadAllText(path);
        var partial = JsonSerializer.Deserialize<SocialSeedFile>(json, JsonOptions);
        if (partial is null)
            return;

        var list = selector(partial);
        if (list.Count == 0)
            return;

        var targetList = selector(target);
        targetList.Clear();
        targetList.AddRange(list);
    }
}
