using Iam.Application.Abstractions;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Iam.Infrastructure.Persistence.Seed;

public static class IamDevDataSeeder
{
    public const string ConfigSection = "DevSeed";

    public static async Task SeedAsync(IServiceProvider services, IConfiguration configuration)
    {
        if (!configuration.GetValue($"{ConfigSection}:Enabled", true))
            return;

        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IamDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<IamDbContext>>();

        var markerEmail = IamDevSeedData.MarkerEmail.Trim().ToLowerInvariant();
        var alreadySeeded = await db.Users.AnyAsync(u => u.Email == markerEmail);
        if (alreadySeeded)
        {
            logger.LogInformation("IAM dev seed skipped (marker user {Email} already exists).", markerEmail);
            return;
        }

        logger.LogWarning("IAM dev seed: inserting {Count} test user(s)...", IamDevSeedData.Users.Count);

        foreach (var seedUser in IamDevSeedData.Users)
        {
            var email = seedUser.Email.Trim().ToLowerInvariant();
            if (await db.Users.AnyAsync(u => u.Email == email))
                continue;

            var user = new User
            {
                Email = email,
                PasswordHash = passwordHasher.Hash(seedUser.Password),
                FullName = seedUser.FullName,
                Role = UserRole.User,
                Status = UserStatus.Active,
                SubscriptionTier = SubscriptionTier.Free,
                EmailVerified = true,
                EmailVerificationToken = null,
                PreferredLanguage = "vi",
                TimeZone = "Asia/Ho_Chi_Minh",
            };

            await db.Users.AddAsync(user);
            logger.LogInformation(
                "IAM dev seed user created: {Email} / password: {Password}",
                email,
                seedUser.Password);
        }

        await db.SaveChangesAsync();
        logger.LogWarning("IAM dev seed completed. Use these accounts to test login without email verification.");
    }
}
