namespace Roadmap.Infrastructure.Persistence.Seed;

public interface IRoadmapDatabaseSeeder
{
    Task InitializeAsync(CancellationToken cancellationToken = default);
}
