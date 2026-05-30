using Iam.Application.Abstractions;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Seed;

/// <summary>Stable IDs and dev seed data (Flutter, Social, Roadmap cross-service references).</summary>
public static class IamSeedData
{
    public const string DefaultDevPassword = "Sync@12345";

    public static readonly Guid DemoUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    public static readonly Guid AdminUserId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    public static readonly Guid PartnerUserId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
    public static readonly Guid DevSeedUserId = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd");

    public const string DemoUserEmail = "demo@sync.local";
    public const string AdminUserEmail = "admin@sync.local";
    public const string PartnerUserEmail = "partner@sync.local";
    public const string DevSeedUserEmail = "dev.seed@sync.local";

    public static IReadOnlyList<Achievement> GetAchievements() =>
    [
        // ── Event-based ────────────────────────────────────────────────────────
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000001"),
            Code = "FIRST_LOGIN",
            Name = "Chào SYNC",
            Description = "Đăng nhập lần đầu vào ứng dụng.",
            XPReward = 50,
            CoinReward = 10,
            IconUrl = "https://cdn.sync.local/achievements/first-login.png",
            RequirementJson = """{"type":"event","event":"user.login","count":1}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000004"),
            Code = "FIRST_WORKOUT",
            Name = "Buổi tập đầu tiên",
            Description = "Hoàn thành buổi tập đầu tiên trên SYNC.",
            XPReward = 100,
            CoinReward = 25,
            IconUrl = "https://cdn.sync.local/achievements/first-workout.png",
            RequirementJson = """{"type":"event","event":"workout.completed","count":1}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000005"),
            Code = "ROADMAP_MILESTONE",
            Name = "Cột mốc Roadmap",
            Description = "Hoàn thành một mốc quan trọng trên lộ trình cá nhân.",
            XPReward = 300,
            CoinReward = 75,
            IconUrl = "https://cdn.sync.local/achievements/roadmap.png",
            RequirementJson = """{"type":"event","event":"roadmap.milestone.completed","count":1}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000006"),
            Code = "FIRST_SOCIAL_POST",
            Name = "Voice đầu tiên",
            Description = "Đăng bài viết đầu tiên lên cộng đồng SYNC.",
            XPReward = 75,
            CoinReward = 20,
            IconUrl = "https://cdn.sync.local/achievements/social-post.png",
            RequirementJson = """{"type":"event","event":"social.post.created","count":1}""",
        },

        // ── Streak ────────────────────────────────────────────────────────────
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000002"),
            Code = "STREAK_7",
            Name = "Week Warrior",
            Description = "Duy trì streak tập luyện 7 ngày liên tiếp.",
            XPReward = 200,
            CoinReward = 50,
            IconUrl = "https://cdn.sync.local/achievements/streak-7.png",
            RequirementJson = """{"type":"streak","days":7}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000003"),
            Code = "STREAK_30",
            Name = "Monthly Machine",
            Description = "Duy trì streak 30 ngày — thói quen đã hình thành.",
            XPReward = 1000,
            CoinReward = 250,
            IconUrl = "https://cdn.sync.local/achievements/streak-30.png",
            RequirementJson = """{"type":"streak","days":30}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000007"),
            Code = "STREAK_100",
            Name = "Streak Legend",
            Description = "100 ngày không ngừng nghỉ — bạn là huyền thoại.",
            XPReward = 3000,
            CoinReward = 1000,
            IconUrl = "https://cdn.sync.local/achievements/streak-100.png",
            RequirementJson = """{"type":"streak","days":100}""",
        },

        // ── Perfect Days ──────────────────────────────────────────────────────
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000008"),
            Code = "PERFECT_3",
            Name = "Triple Threat",
            Description = "Hoàn thành 100% mục tiêu cả ăn lẫn tập 3 ngày liên tiếp.",
            XPReward = 150,
            CoinReward = 40,
            IconUrl = "https://cdn.sync.local/achievements/perfect-3.png",
            RequirementJson = """{"type":"perfect_days","days":3}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000009"),
            Code = "PERFECT_7",
            Name = "Perfect Week",
            Description = "Một tuần hoàn hảo — tập đủ, ăn đúng, không bỏ ngày nào.",
            XPReward = 500,
            CoinReward = 120,
            IconUrl = "https://cdn.sync.local/achievements/perfect-7.png",
            RequirementJson = """{"type":"perfect_days","days":7}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000010"),
            Code = "PERFECT_30",
            Name = "Flawless Month",
            Description = "30 ngày hoàn hảo liên tiếp — kỷ luật tuyệt đối.",
            XPReward = 2000,
            CoinReward = 600,
            IconUrl = "https://cdn.sync.local/achievements/perfect-30.png",
            RequirementJson = """{"type":"perfect_days","days":30}""",
        },

        // ── Level Milestones ──────────────────────────────────────────────────
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000011"),
            Code = "LEVEL_5",
            Name = "Rising Star",
            Description = "Đạt cấp độ 5 — bạn đang tiến bộ thấy rõ.",
            XPReward = 0,
            CoinReward = 100,
            IconUrl = "https://cdn.sync.local/achievements/level-5.png",
            RequirementJson = """{"type":"level","level":5}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000012"),
            Code = "LEVEL_10",
            Name = "Dedicated Athlete",
            Description = "Đạt cấp độ 10 — sự kiên trì của bạn đáng ngưỡng mộ.",
            XPReward = 0,
            CoinReward = 300,
            IconUrl = "https://cdn.sync.local/achievements/level-10.png",
            RequirementJson = """{"type":"level","level":10}""",
        },
        new Achievement
        {
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000013"),
            Code = "LEVEL_25",
            Name = "Elite Athlete",
            Description = "Đạt cấp độ 25 — bạn thuộc tầng lớp elite.",
            XPReward = 0,
            CoinReward = 1000,
            IconUrl = "https://cdn.sync.local/achievements/level-25.png",
            RequirementJson = """{"type":"level","level":25}""",
        },
    ];

    public static User CreateDemoUser(string passwordHash) => new()
    {
        Id = DemoUserId,
        Email = DemoUserEmail,
        PasswordHash = passwordHash,
        FullName = "Nguyễn Demo SYNC",
        AvatarUrl = "https://cdn.sync.local/avatars/demo-user.png",
        Role = UserRole.User,
        Status = UserStatus.Active,
        SubscriptionTier = SubscriptionTier.Free,
        EmailVerified = true,
        PhoneVerified = false,
        PreferredLanguage = "vi",
        TimeZone = "Asia/Ho_Chi_Minh",
        GamificationProfile = new GamificationProfile
        {
            Id = Guid.Parse("e1000001-0000-0000-0000-000000000001"),
            UserId = DemoUserId,
            CurrentLevel = 5,
            CurrentXP = 1250,
            CurrentStreak = 7,
            LongestStreak = 14,
            SyncCoins = 320.5m,
            AchievementPoints = 450,
            ConsecutivePerfectDays = 3,
        },
    };

    public static User CreateAdminUser(string passwordHash) => new()
    {
        Id = AdminUserId,
        Email = AdminUserEmail,
        PasswordHash = passwordHash,
        FullName = "SYNC Admin",
        AvatarUrl = "https://cdn.sync.local/avatars/admin.png",
        Role = UserRole.SystemAdmin,
        Status = UserStatus.Active,
        SubscriptionTier = SubscriptionTier.Ultra,
        EmailVerified = true,
        PhoneVerified = false,
        PreferredLanguage = "vi",
        TimeZone = "Asia/Ho_Chi_Minh",
        GamificationProfile = new GamificationProfile
        {
            Id = Guid.Parse("e1000001-0000-0000-0000-000000000002"),
            UserId = AdminUserId,
            CurrentLevel = 10,
            CurrentXP = 9999,
            CurrentStreak = 30,
            LongestStreak = 60,
            SyncCoins = 5000m,
            AchievementPoints = 2000,
        },
    };

    public static User CreatePartnerUser(string passwordHash) => new()
    {
        Id = PartnerUserId,
        Email = PartnerUserEmail,
        PasswordHash = passwordHash,
        FullName = "SYNC Partner",
        AvatarUrl = "https://cdn.sync.local/avatars/partner.png",
        Role = UserRole.Partner,
        Status = UserStatus.Active,
        SubscriptionTier = SubscriptionTier.Premium,
        EmailVerified = true,
        PhoneVerified = false,
        PreferredLanguage = "vi",
        TimeZone = "Asia/Ho_Chi_Minh",
        GamificationProfile = new GamificationProfile
        {
            Id = Guid.Parse("e1000001-0000-0000-0000-000000000003"),
            UserId = PartnerUserId,
            CurrentLevel = 3,
            CurrentXP = 400,
            CurrentStreak = 2,
            LongestStreak = 5,
            SyncCoins = 100m,
            AchievementPoints = 120,
        },
    };

    public static User CreateDevSeedUser(string passwordHash) => new()
    {
        Id = DevSeedUserId,
        Email = DevSeedUserEmail,
        PasswordHash = passwordHash,
        FullName = "Sync Dev",
        Role = UserRole.User,
        Status = UserStatus.Active,
        SubscriptionTier = SubscriptionTier.Free,
        EmailVerified = true,
        PhoneVerified = false,
        PreferredLanguage = "vi",
        TimeZone = "Asia/Ho_Chi_Minh",
    };

    public static IReadOnlyList<User> GetSeedUsers(string passwordHash) =>
    [
        CreateDemoUser(passwordHash),
        CreateAdminUser(passwordHash),
        CreatePartnerUser(passwordHash),
        CreateDevSeedUser(passwordHash),
    ];

    /// <summary>Applies EF migrations and idempotent dev seed (run once at IAM.API startup).</summary>
    public static class IamDbSeeder
    {
        public static async Task SeedAsync(
            IamDbContext db,
            IPasswordHasher passwordHasher,
            CancellationToken cancellationToken = default)
        {
            await db.Database.MigrateAsync(cancellationToken);

            await SeedAchievementsAsync(db, cancellationToken);
            await SeedUsersAsync(db, passwordHasher, cancellationToken);
        }

        private static async Task SeedAchievementsAsync(IamDbContext db, CancellationToken cancellationToken)
        {
            var seeds = GetAchievements();
            var codes = seeds.Select(a => a.Code).ToList();
            var existingCodes = await db.Achievements
                .AsNoTracking()
                .Where(a => codes.Contains(a.Code))
                .Select(a => a.Code)
                .ToListAsync(cancellationToken);

            var missing = seeds.Where(a => !existingCodes.Contains(a.Code)).ToList();
            if (missing.Count == 0)
                return;

            var now = DateTimeOffset.UtcNow;
            foreach (var achievement in missing)
            {
                achievement.CreatedAt = now;
                achievement.UpdatedAt = now;
            }

            await db.Achievements.AddRangeAsync(missing, cancellationToken);
            await db.SaveChangesAsync(cancellationToken);
        }

        private static async Task SeedUsersAsync(
            IamDbContext db,
            IPasswordHasher passwordHasher,
            CancellationToken cancellationToken)
        {
            var passwordHash = passwordHasher.Hash(DefaultDevPassword);
            var candidates = GetSeedUsers(passwordHash);
            var emails = candidates.Select(u => u.Email).ToList();

            var existingUsers = await db.Users
                .Where(u => emails.Contains(u.Email))
                .ToListAsync(cancellationToken);

            var existingEmails = existingUsers.Select(u => u.Email).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var now = DateTimeOffset.UtcNow;

            foreach (var user in existingUsers)
            {
                user.PasswordHash = passwordHash;
                user.EmailVerified = true;
                if (user.Status == UserStatus.PendingVerification)
                    user.Status = UserStatus.Active;
                user.UpdatedAt = now;
            }

            var toAdd = candidates.Where(u => !existingEmails.Contains(u.Email)).ToList();
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

            if (toAdd.Count > 0)
                await db.Users.AddRangeAsync(toAdd, cancellationToken);

            if (existingUsers.Count > 0 || toAdd.Count > 0)
                await db.SaveChangesAsync(cancellationToken);
        }
    }
}
