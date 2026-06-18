using System.Text.Json;
using Iam.SeedTool.Models;
using Libs.Seed;

namespace Iam.SeedTool.Services;

public sealed class IamSeedReader
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    public IamUsersSeedFile ReadUsers(string? path = null)
    {
        var file = SeedFileLocator.Resolve("iam_users_seed_data.json", path);
        var json = File.ReadAllText(file);
        return JsonSerializer.Deserialize<IamUsersSeedFile>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to deserialize IAM users seed file.");
    }

    public IamAchievementsSeedFile ReadAchievements(string? path = null)
    {
        var file = SeedFileLocator.Resolve("iam_user_profile_seed_data.json", path);
        var json = File.ReadAllText(file);
        return JsonSerializer.Deserialize<IamAchievementsSeedFile>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to deserialize IAM achievements seed file.");
    }
}
