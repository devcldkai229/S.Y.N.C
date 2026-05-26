using Microsoft.Extensions.DependencyInjection;
using Roadmap.Infrastructure.Persistence.Seed;

namespace Roadmap.Infrastructure.Extensions;

public static class RoadmapDatabaseSeedExtensions
{
    public static async Task InitializeRoadmapDatabaseAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var seeder = scope.ServiceProvider.GetRequiredService<IRoadmapDatabaseSeeder>();
        await seeder.InitializeAsync();
    }
}
