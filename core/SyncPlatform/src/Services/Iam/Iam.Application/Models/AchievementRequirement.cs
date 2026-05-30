using System.Text.Json.Serialization;

namespace Iam.Application.Models;

internal sealed record AchievementRequirement(
    [property: JsonPropertyName("type")] string Type,
    [property: JsonPropertyName("days")] int? Days = null,
    [property: JsonPropertyName("count")] int? Count = null,
    [property: JsonPropertyName("event")] string? Event = null,
    [property: JsonPropertyName("level")] int? Level = null);
