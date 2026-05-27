using Iam.Infrastructure.Persistence.Seed;
using Microsoft.Extensions.DependencyInjection;

namespace Iam.Infrastructure.Extensions;

public static class IamDatabaseSeedExtensions
{
    /// <summary>Runs migrations + idempotent seed once per application startup.</summary>
    public static async Task InitializeIamDatabaseAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var seeder = scope.ServiceProvider.GetRequiredService<IIamDatabaseSeeder>();
        await seeder.InitializeAsync();
    }
}
