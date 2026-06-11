using Microsoft.EntityFrameworkCore;

namespace Order.Infrastructure.Persistence.Seed;

public static class OrderSeedData
{
    public static class OrderDbSeeder
    {
        public static async Task SeedAsync(
            OrderDbContext db,
            CancellationToken cancellationToken = default)
        {
            await db.Database.MigrateAsync(cancellationToken);
        }
    }
}
