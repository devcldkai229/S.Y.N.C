namespace Roadmap.Infrastructure.Options;

public class RoadmapSeedOptions
{
    public const string SectionName = "Roadmap:Seed";

    public bool Enabled { get; set; } = true;

    public bool SeedDemoData { get; set; } = true;
}
