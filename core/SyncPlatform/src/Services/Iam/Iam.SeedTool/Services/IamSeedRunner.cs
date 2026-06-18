using Iam.Application.Abstractions;
using Iam.Infrastructure.Persistence;
using Iam.Infrastructure.Persistence.Seed;
using Iam.SeedTool.Models;
using Libs.Seed.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Iam.SeedTool.Services;

public sealed class IamUserSeedRunner
{
    private readonly IamSeedReader _reader;
    private readonly SeedImagePipeline _images;
    private readonly IamDbContext _db;
    private readonly ILogger<IamUserSeedRunner> _logger;

    public IamUserSeedRunner(
        IamSeedReader reader,
        SeedImagePipeline images,
        IamDbContext db,
        ILogger<IamUserSeedRunner> logger)
    {
        _reader = reader;
        _images = images;
        _db = db;
        _logger = logger;
    }

    public async Task<IamSeedReport> RunAsync(IamSeedRunOptions options, CancellationToken cancellationToken = default)
    {
        var report = new IamSeedReport();
        var stats = new SeedImageStats();
        var seed = _reader.ReadUsers(options.UsersFilePath);
        var users = options.Limit.HasValue ? seed.Users.Take(options.Limit.Value).ToList() : seed.Users;
        var userIds = users.Select(u => u.Id).ToHashSet();

        _logger.LogInformation("Seeding {Count} IAM user(s)", users.Count);

        foreach (var dto in users)
        {
            try
            {
                var avatarUrl = await _images.GenerateAvatarAsync(dto.Id, dto.FullName, stats, cancellationToken);
                var user = IamSeedMapper.MapUser(dto, avatarUrl);
                var existing = await _db.Users.FindAsync([dto.Id], cancellationToken);
                if (existing is null)
                {
                    _db.Users.Add(user);
                    report.UsersCreated++;
                }
                else
                {
                    _db.Entry(existing).CurrentValues.SetValues(user);
                    report.UsersUpdated++;
                }
            }
            catch (Exception ex)
            {
                report.UsersFailed++;
                report.Errors.Add($"User {dto.Id}: {ex.Message}");
                _logger.LogError(ex, "Failed to seed user {Id}", dto.Id);
            }
        }

        await _db.SaveChangesAsync(cancellationToken);

        foreach (var dto in seed.BiometricProfiles.Where(x => userIds.Contains(x.UserId)))
        {
            try
            {
                var entity = IamSeedMapper.MapBiometric(dto);
                var existing = await _db.BiometricProfiles.FindAsync([dto.Id], cancellationToken);
                if (existing is null) _db.BiometricProfiles.Add(entity);
                else _db.Entry(existing).CurrentValues.SetValues(entity);
                report.BiometricProfilesUpserted++;
            }
            catch (Exception ex)
            {
                report.Errors.Add($"Biometric {dto.Id}: {ex.Message}");
                _logger.LogError(ex, "Failed biometric {Id}", dto.Id);
            }
        }

        foreach (var dto in seed.UserPreferences.Where(x => userIds.Contains(x.UserId)))
        {
            try
            {
                var entity = IamSeedMapper.MapPreference(dto);
                var existing = await _db.UserPreferences.FindAsync([dto.Id], cancellationToken);
                if (existing is null) _db.UserPreferences.Add(entity);
                else _db.Entry(existing).CurrentValues.SetValues(entity);
                report.UserPreferencesUpserted++;
            }
            catch (Exception ex)
            {
                report.Errors.Add($"Preference {dto.Id}: {ex.Message}");
                _logger.LogError(ex, "Failed preference {Id}", dto.Id);
            }
        }

        foreach (var dto in seed.GamificationProfiles.Where(x => userIds.Contains(x.UserId)))
        {
            try
            {
                var entity = IamSeedMapper.MapGamification(dto);
                var existing = await _db.GamificationProfiles.FindAsync([dto.Id], cancellationToken);
                if (existing is null) _db.GamificationProfiles.Add(entity);
                else _db.Entry(existing).CurrentValues.SetValues(entity);
                report.GamificationProfilesUpserted++;
            }
            catch (Exception ex)
            {
                report.Errors.Add($"Gamification {dto.Id}: {ex.Message}");
                _logger.LogError(ex, "Failed gamification {Id}", dto.Id);
            }
        }

        foreach (var dto in seed.UserAchievements.Where(x => userIds.Contains(x.UserId)))
        {
            try
            {
                var entity = IamSeedMapper.MapUserAchievement(dto);
                var existing = await _db.UserAchievements.FindAsync([dto.Id], cancellationToken);
                if (existing is null) _db.UserAchievements.Add(entity);
                else _db.Entry(existing).CurrentValues.SetValues(entity);
                report.UserAchievementsUpserted++;
            }
            catch (Exception ex)
            {
                report.Errors.Add($"UserAchievement {dto.Id}: {ex.Message}");
                _logger.LogError(ex, "Failed user achievement {Id}", dto.Id);
            }
        }

        await _db.SaveChangesAsync(cancellationToken);
        report.ImageStats = stats;
        report.PrintSummary();
        return report;
    }
}

public sealed class IamAchievementSeedRunner
{
    private readonly IamSeedReader _reader;
    private readonly SeedImagePipeline _images;
    private readonly IamDbContext _db;
    private readonly ILogger<IamAchievementSeedRunner> _logger;

    public IamAchievementSeedRunner(
        IamSeedReader reader,
        SeedImagePipeline images,
        IamDbContext db,
        ILogger<IamAchievementSeedRunner> logger)
    {
        _reader = reader;
        _images = images;
        _db = db;
        _logger = logger;
    }

    public async Task<IamSeedReport> RunAsync(IamSeedRunOptions options, CancellationToken cancellationToken = default)
    {
        var report = new IamSeedReport();
        var stats = new SeedImageStats();
        var seed = _reader.ReadAchievements(options.AchievementsFilePath);
        var achievements = options.Limit.HasValue
            ? seed.Achievements.Take(options.Limit.Value).ToList()
            : seed.Achievements;

        _logger.LogInformation("Seeding {Count} achievement(s)", achievements.Count);

        foreach (var dto in achievements)
        {
            try
            {
                var assetPath = IamSeedMapper.AchievementAssetPath(dto.Code);
                var iconUrl = await _images.AssetAsync(
                    assetPath,
                    dto.Code[..Math.Min(2, dto.Code.Length)],
                    cancellationToken,
                    stats);
                var entity = IamSeedMapper.MapAchievement(dto, iconUrl);
                var existing = await _db.Achievements.FirstOrDefaultAsync(a => a.Code == dto.Code, cancellationToken);
                if (existing is null)
                {
                    _db.Achievements.Add(entity);
                    report.AchievementsCreated++;
                }
                else
                {
                    entity.Id = existing.Id;
                    entity.CreatedAt = existing.CreatedAt;
                    _db.Entry(existing).CurrentValues.SetValues(entity);
                    report.AchievementsUpdated++;
                }
            }
            catch (Exception ex)
            {
                report.AchievementsFailed++;
                report.Errors.Add($"Achievement {dto.Code}: {ex.Message}");
                _logger.LogError(ex, "Failed to seed achievement {Code}", dto.Code);
            }
        }

        await _db.SaveChangesAsync(cancellationToken);
        report.ImageStats = stats;
        report.PrintSummary();
        return report;
    }
}

public sealed class IamDevSeedRunner
{
    private readonly IamDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ILogger<IamDevSeedRunner> _logger;

    public IamDevSeedRunner(
        IamDbContext db,
        IPasswordHasher passwordHasher,
        ILogger<IamDevSeedRunner> logger)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Running IamSeedData dev supplement (achievements + cross-service users)...");
        await IamSeedData.IamDbSeeder.SeedAsync(_db, _passwordHasher, cancellationToken);
        _logger.LogInformation(
            "IamSeedData complete — achievements={Achievements}, users={Users}",
            await _db.Achievements.CountAsync(cancellationToken),
            await _db.Users.CountAsync(cancellationToken));
    }
}

public sealed class IamSeedRunOptions
{
    public int? Limit { get; init; }

    public string? UsersFilePath { get; init; }

    public string? AchievementsFilePath { get; init; }
}

public sealed class IamSeedReport
{
    public int UsersCreated { get; set; }
    public int UsersUpdated { get; set; }
    public int UsersFailed { get; set; }
    public int BiometricProfilesUpserted { get; set; }
    public int UserPreferencesUpserted { get; set; }
    public int GamificationProfilesUpserted { get; set; }
    public int UserAchievementsUpserted { get; set; }
    public int AchievementsCreated { get; set; }
    public int AchievementsUpdated { get; set; }
    public int AchievementsFailed { get; set; }
    public SeedImageStats? ImageStats { get; set; }
    public List<string> Errors { get; } = [];

    public void PrintSummary()
    {
        Console.WriteLine("=== IAM Seed Report ===");
        Console.WriteLine($"Users: created={UsersCreated}, updated={UsersUpdated}, failed={UsersFailed}");
        Console.WriteLine($"BiometricProfiles upserted: {BiometricProfilesUpserted}");
        Console.WriteLine($"UserPreferences upserted: {UserPreferencesUpserted}");
        Console.WriteLine($"GamificationProfiles upserted: {GamificationProfilesUpserted}");
        Console.WriteLine($"UserAchievements upserted: {UserAchievementsUpserted}");
        Console.WriteLine($"Achievements: created={AchievementsCreated}, updated={AchievementsUpdated}, failed={AchievementsFailed}");
        if (ImageStats is not null)
            Console.WriteLine($"Images: uploaded={ImageStats.Uploaded}, skipped={ImageStats.Skipped}, fallback={ImageStats.Fallback}, failed={ImageStats.Failed}");
        if (Errors.Count > 0)
            Console.WriteLine($"Errors ({Errors.Count}): {string.Join(" | ", Errors.Take(5))}");
    }
}
