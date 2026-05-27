using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence;

public static class IamDbSeed
{
    public static async Task SeedAsync(IamDbContext context)
    {
        // 1. Run migrations automatically
        await context.Database.MigrateAsync();

        // 2. Check if a test user already exists
        var testUserId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var userExists = await context.Users.AnyAsync(u => u.Id == testUserId);
        if (userExists)
        {
            return;
        }

        // 3. Create seed data
        var user = new User
        {
            Id = testUserId,
            Email = "testuser@sync.com",
            PasswordHash = "$2a$11$qRzPebh1T8d.4e.4XoM1zexh7Jv2/gJg28tZ3C.t7bL8kK6rWcZ2a", // BCrypt placeholder
            FullName = "Nguyễn Văn Test",
            Role = UserRole.User,
            Status = UserStatus.Active,
            SubscriptionTier = SubscriptionTier.Free,
            EmailVerified = true,
            PhoneVerified = false,
            PreferredLanguage = "vi",
            TimeZone = "Asia/Ho_Chi_Minh",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var userPreference = new UserPreference
        {
            UserId = testUserId,
            AgentPersona = AgentPersona.StrictCoach,
            MotivationStyle = MotivationStyle.Supportive,
            AutoOrderEnabled = false,
            DataSharingConsent = true,
            MarketingConsent = true,
            SmartPushEnabled = true,
            AllowAiGeneratedNotification = true,
            PreferredReminderTime = new TimeSpan(15, 30, 0), // 3:30 PM local time
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var biometricProfile = new BiometricProfile
        {
            UserId = testUserId,
            Gender = Gender.Male,
            DateOfBirth = new DateOnly(1995, 1, 1),
            HeightCm = 175.0m,
            CurrentWeightKg = 70.0m,
            TargetWeightKg = 68.0m,
            FitnessGoal = FitnessGoal.LoseFat,
            ActivityLevel = ActivityLevel.ModeratelyActive,
            FitnessExperienceLevel = FitnessExperienceLevel.Intermediate,
            WorkoutLocationPreference = WorkoutLocationPreference.Gym,
            BaseTDEE = 2200,
            BMR = 1600,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var aiContextProfile = new AIContextProfile
        {
            UserId = testUserId,
            AdherenceScore = 0.85m,
            BurnoutRiskScore = 90.0m, // High burnout to test RecoveryGentleReminder rule and AI Policy
            ChurnRiskScore = 0.15m,
            MotivationScore = 0.80m,
            RecoveryScore = 0.70m,
            StressScore = 0.60m,
            SleepQualityScore = 0.75m,
            WorkoutComplianceScore = 0.90m,
            NutritionComplianceScore = 0.80m,
            AIConfidenceScore = 0.95m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var gamificationProfile = new GamificationProfile
        {
            UserId = testUserId,
            CurrentLevel = 5,
            CurrentXP = 2500,
            CurrentStreak = 8, // Streak >= 7 to trigger AI Policy
            LongestStreak = 12,
            SyncCoins = 150.0m,
            AchievementPoints = 500,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        context.Users.Add(user);
        context.UserPreferences.Add(userPreference);
        context.BiometricProfiles.Add(biometricProfile);
        context.AIContextProfiles.Add(aiContextProfile);
        context.GamificationProfiles.Add(gamificationProfile);

        await context.SaveChangesAsync();
    }
}
