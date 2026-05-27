namespace Iam.Infrastructure.Persistence.Seed;

public interface IIamDatabaseSeeder
{
    /// <summary>Applies migrations (optional) and idempotent seed data. Safe to call on every startup.</summary>
    Task InitializeAsync(CancellationToken cancellationToken = default);
}
