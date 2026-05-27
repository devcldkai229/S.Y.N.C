using Iam.Domain.Enums;
using Iam.Domain.Models;

namespace Iam.Infrastructure.Persistence.Seed;

/// <summary>Stable IDs for local/dev references (Flutter, Social author snapshots, etc.).</summary>
public static class IamSeedData
{
    public static readonly Guid DemoUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    public static readonly Guid AdminUserId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    public static readonly Guid PartnerUserId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");

    public const string DemoUserEmail = "demo@sync.local";
    public const string AdminUserEmail = "admin@sync.local";
    public const string PartnerUserEmail = "partner@sync.local";

    public static IReadOnlyList<Achievement> GetAchievements() =>
    [
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
            Id = Guid.Parse("d1000001-0000-0000-0000-000000000002"),
            Code = "STREAK_7",
            Name = "Chuỗi 7 ngày",
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
            Name = "Chuỗi 30 ngày",
            Description = "Duy trì streak 30 ngày — thói quen đã hình thành.",
            XPReward = 1000,
            CoinReward = 250,
            IconUrl = "https://cdn.sync.local/achievements/streak-30.png",
            RequirementJson = """{"type":"streak","days":30}""",
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
}
