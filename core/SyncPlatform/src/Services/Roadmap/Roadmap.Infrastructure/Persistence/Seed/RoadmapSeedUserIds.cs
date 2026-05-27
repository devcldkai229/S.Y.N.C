namespace Roadmap.Infrastructure.Persistence.Seed;

/// <summary>
/// Must match <c>Iam.Infrastructure.Persistence.Seed.IamSeedData</c> user IDs.
/// </summary>
public static class RoadmapSeedUserIds
{
    public static readonly Guid Demo = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    public static readonly Guid Admin = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    public static readonly Guid Partner = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
}
