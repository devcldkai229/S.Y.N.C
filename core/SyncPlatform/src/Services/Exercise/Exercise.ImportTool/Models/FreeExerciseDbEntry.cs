using System.Text.Json.Serialization;

namespace Exercise.ImportTool.Models;

public sealed class FreeExerciseDbEntry
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("level")]
    public string Level { get; set; } = string.Empty;

    [JsonPropertyName("force")]
    public string? Force { get; set; }

    [JsonPropertyName("mechanic")]
    public string? Mechanic { get; set; }

    [JsonPropertyName("equipment")]
    public string? Equipment { get; set; }

    [JsonPropertyName("primaryMuscles")]
    public List<string> PrimaryMuscles { get; set; } = [];

    [JsonPropertyName("secondaryMuscles")]
    public List<string> SecondaryMuscles { get; set; } = [];

    [JsonPropertyName("instructions")]
    public List<string> Instructions { get; set; } = [];

    [JsonPropertyName("images")]
    public List<string> Images { get; set; } = [];
}
