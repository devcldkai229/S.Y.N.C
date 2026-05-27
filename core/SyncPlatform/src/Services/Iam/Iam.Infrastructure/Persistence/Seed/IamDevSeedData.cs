namespace Iam.Infrastructure.Persistence.Seed;

/// <summary>
/// Fixed dev accounts for local login/API testing (Development only).
/// </summary>
public static class IamDevSeedData
{
    /// <summary>
    /// If this user exists, the database is treated as already seeded.
    /// </summary>
    public const string MarkerEmail = "dev.seed@sync.local";

    public const string DefaultPassword = "Sync@12345";

    public static IReadOnlyList<DevSeedUser> Users { get; } =
    [
        new(MarkerEmail, "Sync Dev", DefaultPassword),
        new("demo@sync.local", "Demo User", DefaultPassword),
    ];
}

public sealed record DevSeedUser(string Email, string FullName, string Password);
