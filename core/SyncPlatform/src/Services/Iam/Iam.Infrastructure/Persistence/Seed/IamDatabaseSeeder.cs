using Iam.Application.Abstractions;
using Iam.Domain.Models;
using Iam.Infrastructure.Options;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Iam.Infrastructure.Persistence.Seed;

public class IamDatabaseSeeder : IIamDatabaseSeeder
{
    private readonly IamDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IamSeedOptions _options;
    private readonly ILogger<IamDatabaseSeeder> _logger;

    public IamDatabaseSeeder(
        IamDbContext db,
        IPasswordHasher passwordHasher,
        IOptions<IamSeedOptions> options,
        ILogger<IamDatabaseSeeder> logger)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _options = options.Value;
        _logger = logger;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            _logger.LogInformation("IAM database seed is disabled (Iam:Seed:Enabled = false).");
            return;
        }

        if (_options.ApplyMigrations)
        {
            _logger.LogInformation("Applying IAM EF Core migrations...");
            await _db.Database.MigrateAsync(cancellationToken);
        }

        if (_options.SeedAchievements)
            await SeedAchievementsAsync(cancellationToken);

        if (_options.SeedDemoUsers)
            await SeedDemoUsersAsync(cancellationToken);
    }

    private async Task SeedAchievementsAsync(CancellationToken cancellationToken)
    {
        var seedCodes = IamSeedData.GetAchievements().Select(a => a.Code).ToList();
        var existingCodes = await _db.Achievements
            .AsNoTracking()
            .Where(a => seedCodes.Contains(a.Code))
            .Select(a => a.Code)
            .ToListAsync(cancellationToken);

        var missing = IamSeedData.GetAchievements()
            .Where(a => !existingCodes.Contains(a.Code))
            .ToList();

        if (missing.Count == 0)
        {
            _logger.LogInformation("IAM achievements seed: catalog already present.");
            return;
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var achievement in missing)
        {
            achievement.CreatedAt = now;
            achievement.UpdatedAt = now;
        }

        await _db.Achievements.AddRangeAsync(missing, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("IAM achievements seed: inserted {Count} achievement(s).", missing.Count);
    }

    private async Task SeedDemoUsersAsync(CancellationToken cancellationToken)
    {
        var passwordHash = _passwordHasher.Hash(_options.DemoUserPassword);
        var candidates = new[]
        {
            IamSeedData.CreateDemoUser(passwordHash),
            IamSeedData.CreateAdminUser(passwordHash),
            IamSeedData.CreatePartnerUser(passwordHash),
        };

        var emails = candidates.Select(u => u.Email).ToList();
        var existingEmails = await _db.Users
            .AsNoTracking()
            .Where(u => emails.Contains(u.Email))
            .Select(u => u.Email)
            .ToListAsync(cancellationToken);

        var toAdd = candidates.Where(u => !existingEmails.Contains(u.Email)).ToList();
        if (toAdd.Count == 0)
        {
            _logger.LogInformation("IAM demo users seed: all demo accounts already exist.");
            return;
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var user in toAdd)
        {
            user.CreatedAt = now;
            user.UpdatedAt = now;
            if (user.GamificationProfile is not null)
            {
                user.GamificationProfile.CreatedAt = now;
                user.GamificationProfile.UpdatedAt = now;
            }
        }

        await _db.Users.AddRangeAsync(toAdd, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "IAM demo users seed: created {Count} account(s). Login password from Iam:Seed:DemoUserPassword. " +
            "Emails: {Emails}",
            toAdd.Count,
            string.Join(", ", toAdd.Select(u => u.Email)));
    }
}
