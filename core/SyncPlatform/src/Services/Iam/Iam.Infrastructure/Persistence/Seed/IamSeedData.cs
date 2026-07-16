using Iam.Application.Abstractions;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Infrastructure.Persistence;
using Libs.Shared.Seed;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Seed;

/// <summary>
/// Stable IDs and dev seed data for the 21 canonical SYNC users (§1 Seed-Dataset-Spec).
/// Cross-service seeds must reference SyncSeedUsers GUIDs only.
/// </summary>
public static class IamSeedData
{
    public const string DefaultDevPassword = SyncSeedUsers.DefaultDevPassword;

    // ── Mid-migration aliases ────────────────────────────────────────────────────
    /// <summary>Standard demo/test user (User02 – Trần Quốc Bảo).</summary>
    public static readonly Guid DemoUserId    = SyncSeedUsers.User02;
    /// <summary>System admin user (User21 – Trương Công Định).</summary>
    public static readonly Guid AdminUserId   = SyncSeedUsers.User21;
    /// <summary>Partner/KOL user (User20 – Mai Thị Kim Chi).</summary>
    public static readonly Guid PartnerUserId = SyncSeedUsers.User20;
    /// <summary>Empty onboarding account (User01 – Nguyễn Minh Khôi).</summary>
    public static readonly Guid EmptyUserId   = SyncSeedUsers.User01;

    // ── Achievement IDs (d1000001-...) ───────────────────────────────────────────
    public static readonly Guid AchievementFirstLoginId       = Guid.Parse("d1000001-0000-0000-0000-000000000001");
    public static readonly Guid AchievementStreak7Id          = Guid.Parse("d1000001-0000-0000-0000-000000000002");
    public static readonly Guid AchievementStreak30Id         = Guid.Parse("d1000001-0000-0000-0000-000000000003");
    public static readonly Guid AchievementFirstWorkoutId     = Guid.Parse("d1000001-0000-0000-0000-000000000004");
    public static readonly Guid AchievementRoadmapMilestoneId = Guid.Parse("d1000001-0000-0000-0000-000000000005");
    public static readonly Guid AchievementFirstSocialPostId  = Guid.Parse("d1000001-0000-0000-0000-000000000006");
    public static readonly Guid AchievementStreak100Id        = Guid.Parse("d1000001-0000-0000-0000-000000000007");
    public static readonly Guid AchievementPerfect3Id         = Guid.Parse("d1000001-0000-0000-0000-000000000008");
    public static readonly Guid AchievementPerfect7Id         = Guid.Parse("d1000001-0000-0000-0000-000000000009");
    public static readonly Guid AchievementPerfect30Id        = Guid.Parse("d1000001-0000-0000-0000-000000000010");
    public static readonly Guid AchievementLevel5Id           = Guid.Parse("d1000001-0000-0000-0000-000000000011");
    public static readonly Guid AchievementLevel10Id          = Guid.Parse("d1000001-0000-0000-0000-000000000012");
    public static readonly Guid AchievementLevel25Id          = Guid.Parse("d1000001-0000-0000-0000-000000000013");

    // ── Achievement catalogue ─────────────────────────────────────────────────────
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
            IconUrl = DevSeedMediaUrls.Achievement("first-login.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("first-workout.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("roadmap.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("social-post.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("streak-7.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("streak-30.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("streak-100.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("perfect-3.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("perfect-7.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("perfect-30.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("level-5.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("level-10.png"),
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
            IconUrl = DevSeedMediaUrls.Achievement("level-25.png"),
            RequirementJson = """{"type":"level","level":25}""",
        },
    ];

    // ── Per-user profile seed definitions ────────────────────────────────────────

    private sealed class UserSeedDef
    {
        public required int Nn { get; init; }
        // Biometric
        public required Gender Gender { get; init; }
        public required DateOnly Dob { get; init; }
        public required decimal Height { get; init; }
        public required decimal Weight { get; init; }
        public required decimal TargetWeight { get; init; }
        public decimal? BodyFat { get; init; }
        public decimal? GoalBodyFat { get; init; }
        public decimal? MuscleMass { get; init; }
        public required FitnessGoal Goal { get; init; }
        public required ActivityLevel Activity { get; init; }
        public required FitnessExperienceLevel Experience { get; init; }
        public WorkoutLocationPreference Location { get; init; } = WorkoutLocationPreference.Hybrid;
        public required int TDEE { get; init; }
        public required int BMR { get; init; }
        public int Protein { get; init; }
        public int Carb { get; init; }
        public int Fat { get; init; }
        public List<string>? Injuries { get; init; }
        public List<string>? Medications { get; init; }
        // Preferences
        public List<AllergyItem>? Allergies { get; init; }
        public List<string>? FavFoods { get; init; }
        public List<string>? DislikedFoods { get; init; }
        public AgentPersona Persona { get; init; } = AgentPersona.FriendlyBuddy;
        public MotivationStyle MotStyle { get; init; } = MotivationStyle.Supportive;
        public bool AutoOrder { get; init; }
        public decimal? MaxOrderDaily { get; init; }
        public decimal? MaxOrderPerOrder { get; init; }
        public bool DataSharing { get; init; } = true;
        public bool Marketing { get; init; }
        public bool SmartPush { get; init; } = true;
        public bool AiNotif { get; init; } = true;
        public TimeSpan? ReminderTime { get; init; }
        // Gamification
        public int Level { get; init; } = 1;
        public long XP { get; init; }
        public int Streak { get; init; }
        public int LongestStreak { get; init; }
        public decimal Coins { get; init; }
        public long AchievPoints { get; init; }
        public int PerfectDays { get; init; }
        // AI Context
        public decimal Adherence { get; init; } = 0.50m;
        public decimal Burnout { get; init; } = 0.30m;
        public decimal Churn { get; init; } = 0.20m;
        public decimal Motivation { get; init; } = 0.60m;
        public decimal Recovery { get; init; } = 0.60m;
        public decimal NutrComp { get; init; } = 0.50m;
        public decimal WorkComp { get; init; } = 0.50m;
        public string PeakEnergy { get; init; } = "07:00-10:00";
        public string InterventionStyle { get; init; } = "Supportive";
        public string Mood { get; init; } = "Neutral";
        public decimal AIConf { get; init; } = 0.70m;
    }

    // ── 20 user profiles (User02–User21) ─────────────────────────────────────────
    private static readonly IReadOnlyList<UserSeedDef> _profileDefs =
    [
        // 02 Trần Quốc Bảo — Premium · Male · LoseFat · Intermediate
        new() {
            Nn = 2, Gender = Gender.Male, Dob = new(1995, 3, 15),
            Height = 175, Weight = 78, TargetWeight = 72, BodyFat = 22, GoalBodyFat = 16, MuscleMass = 58,
            Goal = FitnessGoal.LoseFat, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 2300, BMR = 1780, Protein = 155, Carb = 230, Fat = 68,
            Allergies = [new("đậu phộng", "high", null)],
            FavFoods = ["cá hồi", "phở bò tái", "smoothie protein"],
            DislikedFoods = ["ức gà luộc", "salad rau sống"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Supportive,
            AutoOrder = true, MaxOrderDaily = 300_000, MaxOrderPerOrder = 100_000,
            DataSharing = true, Marketing = false, SmartPush = true, AiNotif = true, ReminderTime = new(7, 0, 0),
            Level = 7, XP = 1840, Streak = 12, LongestStreak = 21, Coins = 340m, AchievPoints = 520, PerfectDays = 3,
            Adherence = 0.78m, Burnout = 0.32m, Churn = 0.18m, Motivation = 0.82m, Recovery = 0.71m,
            NutrComp = 0.74m, WorkComp = 0.81m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Motivated", AIConf = 0.88m,
        },
        // 03 Lê Thị Thu Hà — Free · Female · LoseFat · Beginner
        new() {
            Nn = 3, Gender = Gender.Female, Dob = new(1993, 8, 22),
            Height = 160, Weight = 58, TargetWeight = 54, BodyFat = 28, GoalBodyFat = 22, MuscleMass = 42,
            Goal = FitnessGoal.LoseFat, Activity = ActivityLevel.LightlyActive,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 1780, BMR = 1380, Protein = 100, Carb = 180, Fat = 55,
            Allergies = [new("hải sản", "medium", null)],
            FavFoods = ["cơm gạo lứt", "rau xanh luộc", "trái cây"],
            DislikedFoods = ["thức ăn chiên nhiều dầu", "đồ ngọt"],
            Persona = AgentPersona.CalmMentor, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(6, 30, 0),
            Level = 3, XP = 450, Streak = 5, LongestStreak = 8, Coins = 80m, AchievPoints = 125, PerfectDays = 0,
            Adherence = 0.55m, Burnout = 0.25m, Churn = 0.35m, Motivation = 0.60m, Recovery = 0.65m,
            NutrComp = 0.52m, WorkComp = 0.58m, PeakEnergy = "06:00-09:00",
            InterventionStyle = "Supportive", Mood = "Hopeful", AIConf = 0.65m,
        },
        // 04 Phạm Anh Tuấn — Ultra · Male · BuildMuscle · Advanced (HUB)
        new() {
            Nn = 4, Gender = Gender.Male, Dob = new(1990, 1, 10),
            Height = 178, Weight = 82, TargetWeight = 88, BodyFat = 14, GoalBodyFat = 12, MuscleMass = 72,
            Goal = FitnessGoal.BuildMuscle, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Advanced, Location = WorkoutLocationPreference.Gym,
            TDEE = 2850, BMR = 1920, Protein = 200, Carb = 320, Fat = 80,
            Injuries = ["gối phải — tendinitis nhẹ"],
            FavFoods = ["bò bít tết", "ức gà nướng", "khoai tây luộc"],
            Persona = AgentPersona.StrictCoach, MotStyle = MotivationStyle.DisciplineFocused,
            AutoOrder = true, MaxOrderDaily = 500_000, MaxOrderPerOrder = 200_000,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(5, 30, 0),
            Level = 15, XP = 8200, Streak = 45, LongestStreak = 60, Coins = 1200m, AchievPoints = 2100, PerfectDays = 12,
            Adherence = 0.92m, Burnout = 0.18m, Churn = 0.05m, Motivation = 0.95m, Recovery = 0.88m,
            NutrComp = 0.89m, WorkComp = 0.94m, PeakEnergy = "05:30-08:30",
            InterventionStyle = "DisciplineFocused", Mood = "Focused", AIConf = 0.96m,
        },
        // 05 Vũ Ngọc Lan — Free · Female · GeneralHealth · Beginner
        new() {
            Nn = 5, Gender = Gender.Female, Dob = new(2000, 5, 18),
            Height = 157, Weight = 52, TargetWeight = 50, BodyFat = 26, GoalBodyFat = 22, MuscleMass = 38,
            Goal = FitnessGoal.GeneralHealth, Activity = ActivityLevel.LightlyActive,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 1650, BMR = 1280, Protein = 85, Carb = 175, Fat = 52,
            FavFoods = ["trái cây tươi", "yaourt", "salad"],
            DislikedFoods = ["thịt đỏ nhiều mỡ"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Friendly,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(8, 0, 0),
            Level = 2, XP = 180, Streak = 2, LongestStreak = 4, Coins = 30m, AchievPoints = 50, PerfectDays = 0,
            Adherence = 0.45m, Burnout = 0.20m, Churn = 0.40m, Motivation = 0.55m, Recovery = 0.70m,
            NutrComp = 0.48m, WorkComp = 0.42m, PeakEnergy = "08:00-11:00",
            InterventionStyle = "Friendly", Mood = "Curious", AIConf = 0.60m,
        },
        // 06 Đặng Hoàng Long — Premium · Male · Recomposition · Intermediate
        new() {
            Nn = 6, Gender = Gender.Male, Dob = new(1988, 11, 25),
            Height = 172, Weight = 75, TargetWeight = 78, BodyFat = 18, GoalBodyFat = 15, MuscleMass = 63,
            Goal = FitnessGoal.Recomposition, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Gym,
            TDEE = 2650, BMR = 1850, Protein = 170, Carb = 280, Fat = 72,
            FavFoods = ["ức gà nướng", "cơm trắng", "rau cải xào tỏi"],
            DislikedFoods = ["thực phẩm chế biến sẵn"],
            Persona = AgentPersona.EnergeticTrainer, MotStyle = MotivationStyle.Competitive,
            AutoOrder = true, MaxOrderDaily = 400_000, MaxOrderPerOrder = 150_000,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(6, 0, 0),
            Level = 9, XP = 3200, Streak = 22, LongestStreak = 35, Coins = 580m, AchievPoints = 980, PerfectDays = 7,
            Adherence = 0.85m, Burnout = 0.22m, Churn = 0.12m, Motivation = 0.88m, Recovery = 0.80m,
            NutrComp = 0.82m, WorkComp = 0.87m, PeakEnergy = "06:00-09:00",
            InterventionStyle = "Competitive", Mood = "Pumped", AIConf = 0.90m,
        },
        // 07 Bùi Thị Mai — Premium · Female · LoseFat · Intermediate (Social)
        new() {
            Nn = 7, Gender = Gender.Female, Dob = new(1996, 7, 14),
            Height = 163, Weight = 60, TargetWeight = 56, BodyFat = 27, GoalBodyFat = 22, MuscleMass = 45,
            Goal = FitnessGoal.LoseFat, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 1950, BMR = 1520, Protein = 120, Carb = 200, Fat = 60,
            Allergies = [new("gluten", "low", null)],
            FavFoods = ["phở gà", "cơm gạo lứt", "bơ"],
            DislikedFoods = ["fast food", "nước ngọt"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(7, 30, 0),
            Level = 6, XP = 1200, Streak = 9, LongestStreak = 15, Coins = 200m, AchievPoints = 350, PerfectDays = 3,
            Adherence = 0.72m, Burnout = 0.28m, Churn = 0.22m, Motivation = 0.75m, Recovery = 0.68m,
            NutrComp = 0.70m, WorkComp = 0.73m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Motivated", AIConf = 0.82m,
        },
        // 08 Hoàng Văn Nam — Ultra · Male · BuildMuscle · Advanced (HUB)
        new() {
            Nn = 8, Gender = Gender.Male, Dob = new(1987, 4, 3),
            Height = 183, Weight = 88, TargetWeight = 85, BodyFat = 13, GoalBodyFat = 11, MuscleMass = 79,
            Goal = FitnessGoal.BuildMuscle, Activity = ActivityLevel.Athlete,
            Experience = FitnessExperienceLevel.Advanced, Location = WorkoutLocationPreference.Gym,
            TDEE = 3200, BMR = 2050, Protein = 220, Carb = 380, Fat = 90,
            Injuries = ["lưng dưới — tension mạn tính"],
            FavFoods = ["thịt bò nạc", "protein shake", "khoai lang"],
            Persona = AgentPersona.StrictCoach, MotStyle = MotivationStyle.DisciplineFocused,
            AutoOrder = true, MaxOrderDaily = 600_000, MaxOrderPerOrder = 250_000,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(5, 0, 0),
            Level = 18, XP = 12500, Streak = 85, LongestStreak = 102, Coins = 2500m, AchievPoints = 4200, PerfectDays = 30,
            Adherence = 0.95m, Burnout = 0.25m, Churn = 0.04m, Motivation = 0.97m, Recovery = 0.90m,
            NutrComp = 0.93m, WorkComp = 0.96m, PeakEnergy = "05:00-08:00",
            InterventionStyle = "DisciplineFocused", Mood = "On Fire", AIConf = 0.97m,
        },
        // 09 Ngô Thanh Tùng — Premium · Male · ImproveEndurance · Intermediate
        new() {
            Nn = 9, Gender = Gender.Male, Dob = new(1992, 9, 19),
            Height = 171, Weight = 72, TargetWeight = 70, BodyFat = 20, GoalBodyFat = 16, MuscleMass = 59,
            Goal = FitnessGoal.ImproveEndurance, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Outdoor,
            TDEE = 2500, BMR = 1800, Protein = 145, Carb = 270, Fat = 65,
            FavFoods = ["chuối", "yến mạch ngũ cốc", "gà hầm sả"],
            Persona = AgentPersona.EnergeticTrainer, MotStyle = MotivationStyle.Competitive,
            AutoOrder = true, MaxOrderDaily = 300_000, MaxOrderPerOrder = 120_000,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(6, 0, 0),
            Level = 8, XP = 2400, Streak = 15, LongestStreak = 32, Coins = 420m, AchievPoints = 680, PerfectDays = 5,
            Adherence = 0.83m, Burnout = 0.21m, Churn = 0.14m, Motivation = 0.86m, Recovery = 0.78m,
            NutrComp = 0.80m, WorkComp = 0.85m, PeakEnergy = "06:00-09:30",
            InterventionStyle = "Competitive", Mood = "Energetic", AIConf = 0.88m,
        },
        // 10 Đỗ Thùy Linh — Premium · Female · Recomposition · Intermediate (Social)
        new() {
            Nn = 10, Gender = Gender.Female, Dob = new(1997, 2, 28),
            Height = 162, Weight = 57, TargetWeight = 54, BodyFat = 26, GoalBodyFat = 21, MuscleMass = 44,
            Goal = FitnessGoal.Recomposition, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 1980, BMR = 1540, Protein = 125, Carb = 205, Fat = 62,
            FavFoods = ["salad gà", "hoa quả dầm", "sữa chua"],
            DislikedFoods = ["thực phẩm chiên rán"],
            Persona = AgentPersona.CalmMentor, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(7, 0, 0),
            Level = 7, XP = 1750, Streak = 10, LongestStreak = 18, Coins = 310m, AchievPoints = 490, PerfectDays = 4,
            Adherence = 0.76m, Burnout = 0.30m, Churn = 0.20m, Motivation = 0.78m, Recovery = 0.72m,
            NutrComp = 0.73m, WorkComp = 0.78m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Balanced", AIConf = 0.84m,
        },
        // 11 Nguyễn Hải Đăng — Free · Male · BuildMuscle · Beginner (streak broken)
        new() {
            Nn = 11, Gender = Gender.Male, Dob = new(1999, 12, 5),
            Height = 169, Weight = 66, TargetWeight = 70, BodyFat = 19, GoalBodyFat = 17, MuscleMass = 55,
            Goal = FitnessGoal.BuildMuscle, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 2150, BMR = 1720, Protein = 130, Carb = 240, Fat = 60,
            FavFoods = ["thịt heo luộc", "trứng luộc", "cơm trắng"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Friendly,
            DataSharing = false, SmartPush = true, AiNotif = false, ReminderTime = new(8, 0, 0),
            Level = 4, XP = 850, Streak = 0, LongestStreak = 7, Coins = 120m, AchievPoints = 200, PerfectDays = 0,
            Adherence = 0.58m, Burnout = 0.42m, Churn = 0.38m, Motivation = 0.55m, Recovery = 0.62m,
            NutrComp = 0.55m, WorkComp = 0.52m, PeakEnergy = "08:00-11:00",
            InterventionStyle = "Friendly", Mood = "Tired", AIConf = 0.72m,
        },
        // 12 Trịnh Thị Ngân — Premium · Female · LoseFat · Intermediate (Social)
        new() {
            Nn = 12, Gender = Gender.Female, Dob = new(1994, 6, 17),
            Height = 165, Weight = 62, TargetWeight = 58, BodyFat = 28, GoalBodyFat = 23, MuscleMass = 47,
            Goal = FitnessGoal.LoseFat, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Gym,
            TDEE = 2020, BMR = 1580, Protein = 128, Carb = 210, Fat = 63,
            Allergies = [new("sữa và chế phẩm sữa", "low", null)],
            FavFoods = ["salad rau quả", "thịt gà", "khoai tây nghiền"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(7, 30, 0),
            Level = 6, XP = 1350, Streak = 8, LongestStreak = 12, Coins = 250m, AchievPoints = 420, PerfectDays = 3,
            Adherence = 0.70m, Burnout = 0.32m, Churn = 0.24m, Motivation = 0.72m, Recovery = 0.66m,
            NutrComp = 0.68m, WorkComp = 0.72m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Content", AIConf = 0.80m,
        },
        // 13 Lý Gia Huy — Free · Male · BuildMuscle · Beginner
        new() {
            Nn = 13, Gender = Gender.Male, Dob = new(2001, 9, 12),
            Height = 170, Weight = 63, TargetWeight = 68, BodyFat = 17, GoalBodyFat = 15, MuscleMass = 55,
            Goal = FitnessGoal.BuildMuscle, Activity = ActivityLevel.LightlyActive,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 2050, BMR = 1680, Protein = 125, Carb = 230, Fat = 58,
            FavFoods = ["mỳ trứng", "trứng chiên bơ", "sữa tươi"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Friendly,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(9, 0, 0),
            Level = 2, XP = 220, Streak = 3, LongestStreak = 5, Coins = 45m, AchievPoints = 70, PerfectDays = 0,
            Adherence = 0.42m, Burnout = 0.18m, Churn = 0.45m, Motivation = 0.58m, Recovery = 0.75m,
            NutrComp = 0.40m, WorkComp = 0.45m, PeakEnergy = "09:00-12:00",
            InterventionStyle = "Friendly", Mood = "Casual", AIConf = 0.58m,
        },
        // 14 Phan Khánh Vy — Premium · Female · Maintain · Intermediate (Social)
        new() {
            Nn = 14, Gender = Gender.Female, Dob = new(1995, 4, 9),
            Height = 164, Weight = 55, TargetWeight = 53, BodyFat = 25, GoalBodyFat = 21, MuscleMass = 43,
            Goal = FitnessGoal.Maintain, Activity = ActivityLevel.ModeratelyActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 1940, BMR = 1510, Protein = 118, Carb = 198, Fat = 60,
            FavFoods = ["cơm cuộn hải sản", "salad tuna", "hoa quả mixed"],
            Persona = AgentPersona.CalmMentor, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(7, 0, 0),
            Level = 5, XP = 1100, Streak = 7, LongestStreak = 10, Coins = 180m, AchievPoints = 310, PerfectDays = 2,
            Adherence = 0.74m, Burnout = 0.26m, Churn = 0.18m, Motivation = 0.76m, Recovery = 0.70m,
            NutrComp = 0.72m, WorkComp = 0.75m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Peaceful", AIConf = 0.82m,
        },
        // 15 Võ Minh Quân — Ultra · Male · Recomposition · Advanced (HUB)
        new() {
            Nn = 15, Gender = Gender.Male, Dob = new(1985, 7, 28),
            Height = 180, Weight = 85, TargetWeight = 83, BodyFat = 12, GoalBodyFat = 10, MuscleMass = 78,
            Goal = FitnessGoal.Recomposition, Activity = ActivityLevel.Athlete,
            Experience = FitnessExperienceLevel.Advanced, Location = WorkoutLocationPreference.Gym,
            TDEE = 3100, BMR = 2000, Protein = 210, Carb = 360, Fat = 85,
            FavFoods = ["thịt bò nạc luộc", "cháo yến mạch", "rau xanh nhiều loại"],
            Persona = AgentPersona.StrictCoach, MotStyle = MotivationStyle.DisciplineFocused,
            AutoOrder = true, MaxOrderDaily = 700_000, MaxOrderPerOrder = 300_000,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(5, 30, 0),
            Level = 20, XP = 18000, Streak = 100, LongestStreak = 110, Coins = 3200m, AchievPoints = 5800, PerfectDays = 35,
            Adherence = 0.96m, Burnout = 0.15m, Churn = 0.03m, Motivation = 0.98m, Recovery = 0.92m,
            NutrComp = 0.94m, WorkComp = 0.97m, PeakEnergy = "05:30-08:30",
            InterventionStyle = "DisciplineFocused", Mood = "Peak", AIConf = 0.98m,
        },
        // 16 Đinh Thị Hồng — Free · Female · LoseFat · Beginner
        new() {
            Nn = 16, Gender = Gender.Female, Dob = new(1988, 3, 24),
            Height = 156, Weight = 60, TargetWeight = 55, BodyFat = 30, GoalBodyFat = 25, MuscleMass = 44,
            Goal = FitnessGoal.LoseFat, Activity = ActivityLevel.Sedentary,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 1650, BMR = 1320, Protein = 95, Carb = 175, Fat = 52,
            FavFoods = ["cơm trắng", "rau muống xào", "trái cây"],
            DislikedFoods = ["bài tập cường độ cao"],
            Persona = AgentPersona.CalmMentor, MotStyle = MotivationStyle.Supportive,
            DataSharing = true, SmartPush = false, AiNotif = true, ReminderTime = new(9, 0, 0),
            Level = 1, XP = 90, Streak = 1, LongestStreak = 3, Coins = 15m, AchievPoints = 25, PerfectDays = 0,
            Adherence = 0.35m, Burnout = 0.15m, Churn = 0.55m, Motivation = 0.45m, Recovery = 0.80m,
            NutrComp = 0.38m, WorkComp = 0.32m, PeakEnergy = "09:00-11:00",
            InterventionStyle = "Supportive", Mood = "Hesitant", AIConf = 0.55m,
        },
        // 17 Cao Đức Anh — Premium · Male · BuildMuscle · Intermediate (Social)
        new() {
            Nn = 17, Gender = Gender.Male, Dob = new(1993, 2, 11),
            Height = 174, Weight = 74, TargetWeight = 76, BodyFat = 18, GoalBodyFat = 14, MuscleMass = 63,
            Goal = FitnessGoal.BuildMuscle, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Gym,
            TDEE = 2600, BMR = 1860, Protein = 168, Carb = 278, Fat = 70,
            FavFoods = ["ức gà nướng mật ong", "trứng ốp la", "khoai tây luộc"],
            Persona = AgentPersona.EnergeticTrainer, MotStyle = MotivationStyle.Competitive,
            AutoOrder = true, MaxOrderDaily = 350_000, MaxOrderPerOrder = 140_000,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(6, 30, 0),
            Level = 8, XP = 2800, Streak = 18, LongestStreak = 31, Coins = 480m, AchievPoints = 820, PerfectDays = 6,
            Adherence = 0.84m, Burnout = 0.23m, Churn = 0.13m, Motivation = 0.87m, Recovery = 0.79m,
            NutrComp = 0.81m, WorkComp = 0.86m, PeakEnergy = "06:00-09:30",
            InterventionStyle = "Competitive", Mood = "Driven", AIConf = 0.89m,
        },
        // 18 Dương Bảo Ngọc — Free · Female · GeneralHealth · Beginner
        new() {
            Nn = 18, Gender = Gender.Female, Dob = new(2002, 11, 3),
            Height = 158, Weight = 50, TargetWeight = 52, BodyFat = 23, GoalBodyFat = 21, MuscleMass = 40,
            Goal = FitnessGoal.GeneralHealth, Activity = ActivityLevel.LightlyActive,
            Experience = FitnessExperienceLevel.Beginner, Location = WorkoutLocationPreference.Home,
            TDEE = 1700, BMR = 1340, Protein = 90, Carb = 185, Fat = 53,
            FavFoods = ["bánh mì ngũ cốc", "trứng ốp", "sữa tươi"],
            Persona = AgentPersona.FriendlyBuddy, MotStyle = MotivationStyle.Friendly,
            DataSharing = false, SmartPush = true, AiNotif = true, ReminderTime = new(8, 0, 0),
            Level = 2, XP = 160, Streak = 2, LongestStreak = 3, Coins = 25m, AchievPoints = 40, PerfectDays = 0,
            Adherence = 0.40m, Burnout = 0.15m, Churn = 0.45m, Motivation = 0.58m, Recovery = 0.78m,
            NutrComp = 0.42m, WorkComp = 0.38m, PeakEnergy = "08:00-11:00",
            InterventionStyle = "Friendly", Mood = "Chill", AIConf = 0.60m,
        },
        // 19 Hồ Sĩ Phú — Premium · Male · ImproveEndurance · Intermediate (HUB)
        new() {
            Nn = 19, Gender = Gender.Male, Dob = new(1991, 8, 15),
            Height = 173, Weight = 76, TargetWeight = 74, BodyFat = 17, GoalBodyFat = 14, MuscleMass = 65,
            Goal = FitnessGoal.ImproveEndurance, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Intermediate, Location = WorkoutLocationPreference.Outdoor,
            TDEE = 2680, BMR = 1880, Protein = 162, Carb = 285, Fat = 72,
            FavFoods = ["cháo yến mạch chuối", "ngũ cốc ít đường", "nước dừa"],
            Persona = AgentPersona.EnergeticTrainer, MotStyle = MotivationStyle.Competitive,
            AutoOrder = true, MaxOrderDaily = 400_000, MaxOrderPerOrder = 160_000,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(6, 0, 0),
            Level = 11, XP = 4500, Streak = 30, LongestStreak = 45, Coins = 750m, AchievPoints = 1400, PerfectDays = 10,
            Adherence = 0.88m, Burnout = 0.20m, Churn = 0.10m, Motivation = 0.90m, Recovery = 0.82m,
            NutrComp = 0.85m, WorkComp = 0.89m, PeakEnergy = "06:00-09:00",
            InterventionStyle = "Competitive", Mood = "Energized", AIConf = 0.91m,
        },
        // 20 Mai Thị Kim Chi — Partner · Ultra · Female · Maintain · Advanced (HUB)
        new() {
            Nn = 20, Gender = Gender.Female, Dob = new(1990, 3, 20),
            Height = 167, Weight = 58, TargetWeight = 56, BodyFat = 22, GoalBodyFat = 18, MuscleMass = 48,
            Goal = FitnessGoal.Maintain, Activity = ActivityLevel.VeryActive,
            Experience = FitnessExperienceLevel.Advanced, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 2380, BMR = 1750, Protein = 165, Carb = 260, Fat = 72,
            Allergies = [new("gluten", "medium", null)],
            FavFoods = ["gỏi cuốn tôm", "cơm gạo lứt", "cá hấp gừng"],
            DislikedFoods = ["bánh kẹo nhiều đường", "nước ngọt có ga"],
            Persona = AgentPersona.CalmMentor, MotStyle = MotivationStyle.Supportive,
            AutoOrder = true, MaxOrderDaily = 500_000, MaxOrderPerOrder = 200_000,
            DataSharing = true, Marketing = true, SmartPush = true, AiNotif = true, ReminderTime = new(7, 0, 0),
            Level = 14, XP = 7200, Streak = 55, LongestStreak = 65, Coins = 1600m, AchievPoints = 2800, PerfectDays = 15,
            Adherence = 0.91m, Burnout = 0.16m, Churn = 0.06m, Motivation = 0.93m, Recovery = 0.87m,
            NutrComp = 0.90m, WorkComp = 0.92m, PeakEnergy = "07:00-10:00",
            InterventionStyle = "Supportive", Mood = "Empowered", AIConf = 0.94m,
        },
        // 21 Trương Công Định — SystemAdmin · Ultra · Male · GeneralHealth · Advanced (HUB)
        new() {
            Nn = 21, Gender = Gender.Male, Dob = new(1983, 12, 1),
            Height = 176, Weight = 80, TargetWeight = 78, BodyFat = 15, GoalBodyFat = 13, MuscleMass = 70,
            Goal = FitnessGoal.GeneralHealth, Activity = ActivityLevel.Athlete,
            Experience = FitnessExperienceLevel.Advanced, Location = WorkoutLocationPreference.Hybrid,
            TDEE = 3000, BMR = 1980, Protein = 195, Carb = 340, Fat = 82,
            FavFoods = ["thịt bò luộc rau củ", "cơm trắng nóng", "hoa quả nhiều loại"],
            Persona = AgentPersona.StrictCoach, MotStyle = MotivationStyle.DisciplineFocused,
            AutoOrder = true, MaxOrderDaily = 800_000, MaxOrderPerOrder = 400_000,
            DataSharing = true, SmartPush = true, AiNotif = true, ReminderTime = new(5, 0, 0),
            Level = 25, XP = 35000, Streak = 120, LongestStreak = 150, Coins = 8000m, AchievPoints = 9500, PerfectDays = 45,
            Adherence = 0.97m, Burnout = 0.12m, Churn = 0.02m, Motivation = 0.99m, Recovery = 0.94m,
            NutrComp = 0.96m, WorkComp = 0.98m, PeakEnergy = "05:00-08:00",
            InterventionStyle = "DisciplineFocused", Mood = "Peak", AIConf = 0.99m,
        },
    ];

    // ── GUID helpers ─────────────────────────────────────────────────────────────

    /// <summary>Stable GUID for a user achievement: per-user prefix + 1-based index within that user's achievement list.</summary>
    private static Guid UserAchievementId(int nn, int subIdx) =>
        SyncSeedUsers.ChildId($"c{nn:D7}", subIdx);

    // ── Achievement IDs for a given profile (stable ordered list) ────────────────

    private static IReadOnlyList<Guid> GetAchievementIds(UserSeedDef d)
    {
        // Hubs post frequently; intermediate social users also have FIRST_SOCIAL_POST
        bool isHub             = d.Nn is 4 or 8 or 15 or 19 or 20 or 21;
        bool isSocialIntermediate = d.Nn is 2 or 7 or 10 or 12 or 14 or 17;
        bool hasRoadmapMilestone  = d.Level >= 8 || d.Experience == FitnessExperienceLevel.Advanced;

        var list = new List<Guid>(13)
        {
            AchievementFirstLoginId,
            AchievementFirstWorkoutId,
        };

        if (isHub || isSocialIntermediate) list.Add(AchievementFirstSocialPostId);
        if (hasRoadmapMilestone)           list.Add(AchievementRoadmapMilestoneId);
        if (d.LongestStreak >= 7)          list.Add(AchievementStreak7Id);
        if (d.LongestStreak >= 30)         list.Add(AchievementStreak30Id);
        if (d.LongestStreak >= 100)        list.Add(AchievementStreak100Id);
        if (d.PerfectDays >= 3)            list.Add(AchievementPerfect3Id);
        if (d.PerfectDays >= 7)            list.Add(AchievementPerfect7Id);
        if (d.PerfectDays >= 30)           list.Add(AchievementPerfect30Id);
        if (d.Level >= 5)                  list.Add(AchievementLevel5Id);
        if (d.Level >= 10)                 list.Add(AchievementLevel10Id);
        if (d.Level >= 25)                 list.Add(AchievementLevel25Id);

        return list;
    }

    private static DateTimeOffset ComputeUnlockDate(DateTimeOffset now, UserSeedDef d, Guid achievementId)
    {
        int joinDaysAgo = d.Level * 7 + 10;

        if (achievementId == AchievementFirstLoginId)       return now.AddDays(-joinDaysAgo);
        if (achievementId == AchievementFirstWorkoutId)     return now.AddDays(-joinDaysAgo + 2);
        if (achievementId == AchievementRoadmapMilestoneId) return now.AddDays(-(joinDaysAgo / 2));
        if (achievementId == AchievementFirstSocialPostId)  return now.AddDays(-(joinDaysAgo / 3 + 5));
        if (achievementId == AchievementStreak7Id)          return now.AddDays(-(d.LongestStreak + 14));
        if (achievementId == AchievementStreak30Id)         return now.AddDays(-(d.LongestStreak + 10));
        if (achievementId == AchievementStreak100Id)        return now.AddDays(-(d.LongestStreak + 5));
        if (achievementId == AchievementPerfect3Id)         return now.AddDays(-(d.PerfectDays + 14));
        if (achievementId == AchievementPerfect7Id)         return now.AddDays(-(d.PerfectDays + 21));
        if (achievementId == AchievementPerfect30Id)        return now.AddDays(-(d.PerfectDays + 35));
        if (achievementId == AchievementLevel5Id)           return now.AddDays(-Math.Max(5, (d.Level - 5) * 7 + 5));
        if (achievementId == AchievementLevel10Id)          return now.AddDays(-Math.Max(5, (d.Level - 10) * 7 + 5));
        if (achievementId == AchievementLevel25Id)          return now.AddDays(-5);
        return now.AddDays(-30);
    }

    // ── Entity factories ──────────────────────────────────────────────────────────

    private static BiometricProfile MakeBiometric(UserSeedDef d) => new()
    {
        Id = SyncSeedUsers.ChildId("b1000001", d.Nn),
        UserId = SyncSeedUsers.Id(d.Nn),
        Gender = d.Gender,
        DateOfBirth = d.Dob,
        HeightCm = d.Height,
        CurrentWeightKg = d.Weight,
        TargetWeightKg = d.TargetWeight,
        CurrentBodyFatPercentage = d.BodyFat,
        GoalBodyFatPercentage = d.GoalBodyFat,
        MuscleMassKg = d.MuscleMass,
        FitnessGoal = d.Goal,
        ActivityLevel = d.Activity,
        FitnessExperienceLevel = d.Experience,
        WorkoutLocationPreference = d.Location,
        BaseTDEE = d.TDEE,
        BMR = d.BMR,
        DailyProteinTargetGram = d.Protein,
        DailyCarbTargetGram = d.Carb,
        DailyFatTargetGram = d.Fat,
        Injuries = d.Injuries,
        Medications = d.Medications,
    };

    private static UserPreference MakePreference(UserSeedDef d) => new()
    {
        Id = SyncSeedUsers.ChildId("b2000001", d.Nn),
        UserId = SyncSeedUsers.Id(d.Nn),
        Allergies = d.Allergies,
        FavoriteFoods = d.FavFoods,
        DislikedFoods = d.DislikedFoods,
        AgentPersona = d.Persona,
        MotivationStyle = d.MotStyle,
        AutoOrderEnabled = d.AutoOrder,
        MaxAutoOrderLimitDaily = d.MaxOrderDaily,
        MaxAutoOrderLimitPerOrder = d.MaxOrderPerOrder,
        DataSharingConsent = d.DataSharing,
        MarketingConsent = d.Marketing,
        SmartPushEnabled = d.SmartPush,
        AllowAiGeneratedNotification = d.AiNotif,
        PreferredReminderTime = d.ReminderTime,
    };

    private static AIContextProfile MakeAIContext(UserSeedDef d, DateTimeOffset now) => new()
    {
        Id = SyncSeedUsers.ChildId("b3000001", d.Nn),
        UserId = SyncSeedUsers.Id(d.Nn),
        AdherenceScore = d.Adherence,
        BurnoutRiskScore = d.Burnout,
        ChurnRiskScore = d.Churn,
        MotivationScore = d.Motivation,
        RecoveryScore = d.Recovery,
        NutritionComplianceScore = d.NutrComp,
        WorkoutComplianceScore = d.WorkComp,
        PeakEnergyTimeWindow = d.PeakEnergy,
        PreferredInterventionStyle = d.InterventionStyle,
        CurrentMood = d.Mood,
        AIConfidenceScore = d.AIConf,
        LastBurnoutDetectedAt = d.Burnout > 0.50m ? now.AddDays(-14) : null,
        LastWorkoutSkippedAt = d.WorkComp > 0.85m ? now.AddDays(-14) : now.AddDays(-5),
        LastCheatMealAt = d.NutrComp > 0.80m ? now.AddDays(-7) : now.AddDays(-2),
        LastReplanAt = now.AddDays(-d.Level * 3),
    };

    private static GamificationProfile MakeGamification(UserSeedDef d, DateTimeOffset now) => new()
    {
        Id = SyncSeedUsers.ChildId("b4000001", d.Nn),
        UserId = SyncSeedUsers.Id(d.Nn),
        CurrentLevel = d.Level,
        CurrentXP = d.XP,
        CurrentStreak = d.Streak,
        LongestStreak = d.LongestStreak,
        SyncCoins = d.Coins,
        AchievementPoints = d.AchievPoints,
        ConsecutivePerfectDays = d.PerfectDays,
        LastActivityDate = d.Nn == 11
            ? now.AddDays(-2)
            : (d.Streak > 0 ? (d.Streak >= 30 ? now : now.AddDays(-1)) : (DateTimeOffset?)null),
    };

    // ── IamDbSeeder ───────────────────────────────────────────────────────────────

    /// <summary>Applies EF migrations and idempotent dev seed (run once at IAM.API startup).</summary>
    public static class IamDbSeeder
    {
        public static async Task SeedAsync(
            IamDbContext db,
            IPasswordHasher passwordHasher,
            CancellationToken cancellationToken = default)
        {
            await db.Database.MigrateAsync(cancellationToken);

            var now = DateTimeOffset.UtcNow;
            await SeedAchievementsAsync(db, now, cancellationToken);
            await SeedUsersAsync(db, passwordHasher, now, cancellationToken);
            await SeedUserProfilesAsync(db, now, cancellationToken);
            await SeedUserAchievementsAsync(db, now, cancellationToken);
        }

        // ── Achievements ──────────────────────────────────────────────────────

        private static async Task SeedAchievementsAsync(
            IamDbContext db,
            DateTimeOffset now,
            CancellationToken ct)
        {
            var seeds = GetAchievements();
            var codes = seeds.Select(a => a.Code).ToList();

            var existing = await db.Achievements
                .Where(a => codes.Contains(a.Code))
                .ToListAsync(ct);

            var existingCodes = existing.Select(a => a.Code).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var seedByCode    = seeds.ToDictionary(a => a.Code, StringComparer.OrdinalIgnoreCase);

            var toAdd = seeds.Where(a => !existingCodes.Contains(a.Code)).ToList();
            foreach (var a in toAdd) { a.CreatedAt = now; a.UpdatedAt = now; }
            if (toAdd.Count > 0)
                await db.Achievements.AddRangeAsync(toAdd, ct);

            foreach (var a in existing)
            {
                if (!seedByCode.TryGetValue(a.Code, out var seed)) continue;
                var migrated = DevSeedMediaUrls.MigrateLegacyUrl(seed.IconUrl);
                if (!string.Equals(a.IconUrl, migrated, StringComparison.Ordinal))
                {
                    a.IconUrl    = migrated;
                    a.UpdatedAt  = now;
                }
            }

            if (toAdd.Count > 0 || existing.Count > 0)
                await db.SaveChangesAsync(ct);
        }

        // ── Users ─────────────────────────────────────────────────────────────

        private static async Task SeedUsersAsync(
            IamDbContext db,
            IPasswordHasher passwordHasher,
            DateTimeOffset now,
            CancellationToken ct)
        {
            var passwordHash = passwordHasher.Hash(DefaultDevPassword);
            var allDefs      = SyncSeedUsers.All;
            var emails       = allDefs.Select(d => d.Email).ToList();

            var existing     = await db.Users.Where(u => emails.Contains(u.Email)).ToListAsync(ct);
            var existingEmails = existing.Select(u => u.Email).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var defByEmail   = allDefs.ToDictionary(d => d.Email, StringComparer.OrdinalIgnoreCase);

            foreach (var user in existing)
            {
                user.PasswordHash  = passwordHash;
                user.EmailVerified = true;
                if (user.Status == UserStatus.PendingVerification)
                    user.Status = UserStatus.Active;
                if (defByEmail.TryGetValue(user.Email, out var def))
                {
                    user.FullName         = def.FullName;
                    user.Role             = ParseRole(def.Role);
                    user.SubscriptionTier = ParseTier(def.Tier);
                    user.AvatarUrl        = SyncSeedUsers.AvatarUrl(def.Email);
                }
                user.UpdatedAt = now;
            }

            var toAdd = allDefs
                .Where(d => !existingEmails.Contains(d.Email))
                .Select(d => new User
                {
                    Id                = d.Id,
                    Email             = d.Email,
                    PasswordHash      = passwordHash,
                    FullName          = d.FullName,
                    AvatarUrl         = SyncSeedUsers.AvatarUrl(d.Email),
                    Role              = ParseRole(d.Role),
                    Status            = UserStatus.Active,
                    SubscriptionTier  = ParseTier(d.Tier),
                    EmailVerified     = true,
                    PreferredLanguage = "vi",
                    TimeZone          = "Asia/Ho_Chi_Minh",
                    CreatedAt         = now,
                    UpdatedAt         = now,
                })
                .ToList();

            if (toAdd.Count > 0)
                await db.Users.AddRangeAsync(toAdd, ct);

            if (existing.Count > 0 || toAdd.Count > 0)
                await db.SaveChangesAsync(ct);
        }

        // ── Per-user profiles (Users 02-21) ───────────────────────────────────

        private static async Task SeedUserProfilesAsync(
            IamDbContext db,
            DateTimeOffset now,
            CancellationToken ct)
        {
            foreach (var pd in _profileDefs)
            {
                var userId = SyncSeedUsers.Id(pd.Nn);

                // Biometric
                var bioSeed = MakeBiometric(pd);
                var bio     = await db.BiometricProfiles.FirstOrDefaultAsync(b => b.UserId == userId, ct);
                if (bio is null)
                {
                    bioSeed.CreatedAt = now; bioSeed.UpdatedAt = now;
                    await db.BiometricProfiles.AddAsync(bioSeed, ct);
                }
                else { ApplyBiometricSeed(bioSeed, bio); bio.UpdatedAt = now; }

                // Preference
                var prefSeed = MakePreference(pd);
                var pref     = await db.UserPreferences.FirstOrDefaultAsync(p => p.UserId == userId, ct);
                if (pref is null)
                {
                    prefSeed.CreatedAt = now; prefSeed.UpdatedAt = now;
                    await db.UserPreferences.AddAsync(prefSeed, ct);
                }
                else { ApplyPreferenceSeed(prefSeed, pref); pref.UpdatedAt = now; }

                // AI Context
                var aiSeed = MakeAIContext(pd, now);
                var ai     = await db.AIContextProfiles.FirstOrDefaultAsync(a => a.UserId == userId, ct);
                if (ai is null)
                {
                    aiSeed.CreatedAt = now; aiSeed.UpdatedAt = now;
                    await db.AIContextProfiles.AddAsync(aiSeed, ct);
                }
                else { ApplyAIContextSeed(aiSeed, ai); ai.UpdatedAt = now; }

                // Gamification
                var gameSeed = MakeGamification(pd, now);
                var game     = await db.GamificationProfiles.FirstOrDefaultAsync(g => g.UserId == userId, ct);
                if (game is null)
                {
                    gameSeed.CreatedAt = now; gameSeed.UpdatedAt = now;
                    await db.GamificationProfiles.AddAsync(gameSeed, ct);
                }
                else { ApplyGamificationSeed(gameSeed, game); game.UpdatedAt = now; }

                await db.SaveChangesAsync(ct);
            }
        }

        // ── User achievements (Users 02-21) ───────────────────────────────────

        private static async Task SeedUserAchievementsAsync(
            IamDbContext db,
            DateTimeOffset now,
            CancellationToken ct)
        {
            foreach (var pd in _profileDefs)
            {
                var userId       = SyncSeedUsers.Id(pd.Nn);
                var achIds       = GetAchievementIds(pd);
                var existingAchIds = await db.UserAchievements
                    .Where(ua => ua.UserId == userId)
                    .Select(ua => ua.AchievementId)
                    .ToListAsync(ct);
                var existingSet = existingAchIds.ToHashSet();

                var toAdd = new List<UserAchievement>();
                for (int i = 0; i < achIds.Count; i++)
                {
                    var achId = achIds[i];
                    if (existingSet.Contains(achId)) continue;
                    toAdd.Add(new UserAchievement
                    {
                        Id            = UserAchievementId(pd.Nn, i + 1),
                        UserId        = userId,
                        AchievementId = achId,
                        UnlockedAt    = ComputeUnlockDate(now, pd, achId),
                        CreatedAt     = now,
                        UpdatedAt     = now,
                    });
                }

                if (toAdd.Count > 0)
                {
                    await db.UserAchievements.AddRangeAsync(toAdd, ct);
                    await db.SaveChangesAsync(ct);
                }
            }
        }

        // ── Apply helpers (used on update path) ──────────────────────────────

        private static void ApplyGamificationSeed(GamificationProfile seed, GamificationProfile target)
        {
            target.CurrentLevel          = seed.CurrentLevel;
            target.CurrentXP             = seed.CurrentXP;
            target.CurrentStreak         = seed.CurrentStreak;
            target.LongestStreak         = seed.LongestStreak;
            target.SyncCoins             = seed.SyncCoins;
            target.AchievementPoints     = seed.AchievementPoints;
            target.ConsecutivePerfectDays = seed.ConsecutivePerfectDays;
            target.LastActivityDate      = seed.LastActivityDate;
        }

        private static void ApplyBiometricSeed(BiometricProfile seed, BiometricProfile target)
        {
            target.Gender                     = seed.Gender;
            target.DateOfBirth                = seed.DateOfBirth;
            target.HeightCm                   = seed.HeightCm;
            target.CurrentWeightKg            = seed.CurrentWeightKg;
            target.TargetWeightKg             = seed.TargetWeightKg;
            target.CurrentBodyFatPercentage   = seed.CurrentBodyFatPercentage;
            target.GoalBodyFatPercentage      = seed.GoalBodyFatPercentage;
            target.MuscleMassKg               = seed.MuscleMassKg;
            target.FitnessGoal                = seed.FitnessGoal;
            target.ActivityLevel              = seed.ActivityLevel;
            target.FitnessExperienceLevel     = seed.FitnessExperienceLevel;
            target.WorkoutLocationPreference  = seed.WorkoutLocationPreference;
            target.BaseTDEE                   = seed.BaseTDEE;
            target.BMR                        = seed.BMR;
            target.DailyProteinTargetGram     = seed.DailyProteinTargetGram;
            target.DailyCarbTargetGram        = seed.DailyCarbTargetGram;
            target.DailyFatTargetGram         = seed.DailyFatTargetGram;
            target.Injuries                   = seed.Injuries;
            target.Medications                = seed.Medications;
        }

        private static void ApplyPreferenceSeed(UserPreference seed, UserPreference target)
        {
            target.Allergies                    = seed.Allergies;
            target.FavoriteFoods                = seed.FavoriteFoods;
            target.DislikedFoods                = seed.DislikedFoods;
            target.AgentPersona                 = seed.AgentPersona;
            target.MotivationStyle              = seed.MotivationStyle;
            target.AutoOrderEnabled             = seed.AutoOrderEnabled;
            target.MaxAutoOrderLimitDaily       = seed.MaxAutoOrderLimitDaily;
            target.MaxAutoOrderLimitPerOrder    = seed.MaxAutoOrderLimitPerOrder;
            target.DataSharingConsent           = seed.DataSharingConsent;
            target.MarketingConsent             = seed.MarketingConsent;
            target.SmartPushEnabled             = seed.SmartPushEnabled;
            target.AllowAiGeneratedNotification = seed.AllowAiGeneratedNotification;
            target.PreferredReminderTime        = seed.PreferredReminderTime;
        }

        private static void ApplyAIContextSeed(AIContextProfile seed, AIContextProfile target)
        {
            target.AdherenceScore             = seed.AdherenceScore;
            target.BurnoutRiskScore           = seed.BurnoutRiskScore;
            target.ChurnRiskScore             = seed.ChurnRiskScore;
            target.MotivationScore            = seed.MotivationScore;
            target.RecoveryScore              = seed.RecoveryScore;
            target.NutritionComplianceScore   = seed.NutritionComplianceScore;
            target.WorkoutComplianceScore     = seed.WorkoutComplianceScore;
            target.PeakEnergyTimeWindow       = seed.PeakEnergyTimeWindow;
            target.PreferredInterventionStyle = seed.PreferredInterventionStyle;
            target.CurrentMood                = seed.CurrentMood;
            target.AIConfidenceScore          = seed.AIConfidenceScore;
            target.LastBurnoutDetectedAt      = seed.LastBurnoutDetectedAt;
            target.LastWorkoutSkippedAt       = seed.LastWorkoutSkippedAt;
            target.LastCheatMealAt            = seed.LastCheatMealAt;
            target.LastReplanAt               = seed.LastReplanAt;
        }

        // ── Role / tier parsers ───────────────────────────────────────────────

        private static UserRole ParseRole(string role) => role switch
        {
            "SystemAdmin" => UserRole.SystemAdmin,
            "Partner"     => UserRole.Partner,
            _             => UserRole.User,
        };

        private static SubscriptionTier ParseTier(string tier) => tier switch
        {
            "Ultra"   => SubscriptionTier.Ultra,
            "Premium" => SubscriptionTier.Premium,
            _         => SubscriptionTier.Free,
        };
    }
}
