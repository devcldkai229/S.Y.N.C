namespace Social.Infrastructure.Persistence.Seed;

public interface ISocialDatabaseSeeder
{
    Task InitializeAsync(CancellationToken cancellationToken = default);
}
