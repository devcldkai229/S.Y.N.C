using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using Social.Infrastructure.Options;
using Social.Infrastructure.Persistence.Seed;

namespace Social.Infrastructure.Extensions;

public static class SocialDatabaseSeedExtensions
{
    public static async Task InitializeSocialDatabaseAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IMongoDatabase>();
        var seedOptions = scope.ServiceProvider.GetRequiredService<IOptions<SocialSeedOptions>>().Value;
        await SocialSeedData.SeedAsync(db, seedOptions.Enabled);
    }
}
