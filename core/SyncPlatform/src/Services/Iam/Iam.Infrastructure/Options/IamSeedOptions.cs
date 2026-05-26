namespace Iam.Infrastructure.Options;

public class IamSeedOptions
{
    public const string SectionName = "Iam:Seed";

    /// <summary>When false, startup seed is skipped entirely.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>Applies pending EF Core migrations before seeding.</summary>
    public bool ApplyMigrations { get; set; } = true;

    /// <summary>Inserts the achievement catalog when missing.</summary>
    public bool SeedAchievements { get; set; } = true;

    /// <summary>Inserts demo users (idempotent by email) for local development.</summary>
    public bool SeedDemoUsers { get; set; } = true;

    /// <summary>Password for all seeded demo accounts (login via POST /api/v1/auth/login).</summary>
    public string DemoUserPassword { get; set; } = "SyncDemo123!";
}
