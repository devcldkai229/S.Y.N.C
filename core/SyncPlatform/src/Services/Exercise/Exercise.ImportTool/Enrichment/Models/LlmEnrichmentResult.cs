using System.Text.Json.Serialization;



namespace Exercise.ImportTool.Enrichment.Models;



public sealed class LlmEnrichmentResult

{

    [JsonPropertyName("nameVi")]

    public string? NameVi { get; set; }



    [JsonPropertyName("instructionsVi")]

    public List<string> InstructionsVi { get; set; } = [];



    [JsonPropertyName("commonMistakes")]

    public List<string> CommonMistakes { get; set; } = [];



    [JsonPropertyName("contraindications")]

    public List<string> Contraindications { get; set; } = [];



    [JsonPropertyName("recommendedGoals")]

    public List<string> RecommendedGoals { get; set; } = [];

}


