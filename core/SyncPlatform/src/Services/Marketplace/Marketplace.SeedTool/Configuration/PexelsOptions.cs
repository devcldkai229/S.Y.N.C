namespace Marketplace.SeedTool.Configuration;

public class PexelsOptions
{
    public const string SectionName = "Pexels";

    public string ApiKey { get; set; } = string.Empty;

    public int MinDelayMs { get; set; } = 350;

    public int MaxRetries { get; set; } = 3;
}
