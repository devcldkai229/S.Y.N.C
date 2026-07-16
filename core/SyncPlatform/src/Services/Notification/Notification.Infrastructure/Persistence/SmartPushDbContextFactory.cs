using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Notification.Infrastructure.Persistence;

public class SmartPushDbContextFactory : IDesignTimeDbContextFactory<SmartPushDbContext>
{
    public SmartPushDbContext CreateDbContext(string[] args)
    {
        var cs = Environment.GetEnvironmentVariable("SMART_PUSH_DATABASE")
            ?? "Host=localhost;Port=5434;Database=sync_smart_push;Username=postgres;Password=12345;Include Error Detail=true";

        var options = new DbContextOptionsBuilder<SmartPushDbContext>()
            .UseNpgsql(cs, npgsql =>
            {
                npgsql.MigrationsHistoryTable("__ef_migrations_history", "smart_push");
            })
            .UseSnakeCaseNamingConvention()
            .Options;

        return new SmartPushDbContext(options);
    }
}
