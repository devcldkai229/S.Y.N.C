namespace Exercise.Application.Configuration;

public class EnrichmentOptions
{
    public const string SectionName = "Enrichment";

    public string OllamaBaseUrl { get; set; } = "http://localhost:11434";
    public string Model { get; set; } = "qwen2.5:latest";
    public double Temperature { get; set; } = 0.2;
    public int Concurrency { get; set; } = 2;
}
