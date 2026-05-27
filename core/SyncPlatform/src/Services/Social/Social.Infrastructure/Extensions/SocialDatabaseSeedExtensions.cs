using Microsoft.Extensions.DependencyInjection;
using Social.Infrastructure.Persistence.Seed;

namespace Social.Infrastructure.Extensions;

public static class SocialDatabaseSeedExtensions
{
    public static async Task InitializeSocialDatabaseAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var seeder = scope.ServiceProvider.GetRequiredService<ISocialDatabaseSeeder>();
        await seeder.InitializeAsync();
    }
}
