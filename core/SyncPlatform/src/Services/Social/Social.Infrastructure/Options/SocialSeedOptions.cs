namespace Social.Infrastructure.Options;

public class SocialSeedOptions
{
    public const string SectionName = "Social:Seed";

    public bool Enabled { get; set; } = true;

    public bool SeedDemoData { get; set; } = true;
}
