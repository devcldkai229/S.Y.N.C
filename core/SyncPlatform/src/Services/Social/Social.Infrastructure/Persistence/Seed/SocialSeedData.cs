using MongoDB.Driver.GeoJsonObjectModel;
using Social.Application.Helpers;
using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Infrastructure.Persistence.Seed;

/// <summary>Diverse Vietnamese fitness seed data for the Social MongoDB collections.</summary>
public static class SocialSeedData
{
    public static readonly Guid SeedMarkerPostId = Guid.Parse("c1000001-0000-0000-0000-000000000001");

    // ─── Post IDs ───────────────────────────────────────────────────────────
    public static readonly Guid Post1Id = SeedMarkerPostId;
    public static readonly Guid Post2Id = Guid.Parse("c1000002-0000-0000-0000-000000000002");
    public static readonly Guid Post3Id = Guid.Parse("c1000003-0000-0000-0000-000000000003");
    public static readonly Guid Post4Id = Guid.Parse("c1000004-0000-0000-0000-000000000004");
    public static readonly Guid Post5Id = Guid.Parse("c1000005-0000-0000-0000-000000000005");
    public static readonly Guid Post6Id = Guid.Parse("c1000006-0000-0000-0000-000000000006");
    public static readonly Guid Post7Id = Guid.Parse("c1000007-0000-0000-0000-000000000007");
    public static readonly Guid Post8Id = Guid.Parse("c1000008-0000-0000-0000-000000000008");
    public static readonly Guid Post9Id = Guid.Parse("c1000009-0000-0000-0000-000000000009");
    public static readonly Guid Post10Id = Guid.Parse("c1000010-0000-0000-0000-000000000010");

    // ─── Challenge IDs ──────────────────────────────────────────────────────
    public static readonly Guid ChallengeActiveId = Guid.Parse("c8000001-0000-0000-0000-000000000001");
    public static readonly Guid ChallengeUpcomingId = Guid.Parse("c8000002-0000-0000-0000-000000000002");
    public static readonly Guid ChallengeCompletedId = Guid.Parse("c8000003-0000-0000-0000-000000000003");
    public static readonly Guid ChallengeUpcomingWaitingId = Guid.Parse("c8000004-0000-0000-0000-000000000004");

    private static GeoJsonPoint<GeoJson2DGeographicCoordinates> HcmLocation() =>
        new(new GeoJson2DGeographicCoordinates(106.660172, 10.762622));

    public static IReadOnlyList<Post> GetSeedPosts(DateTimeOffset utcNow) =>
    [
        new Post
        {
            Id = Post1Id,
            AuthorId = SocialSeedUserIds.Beginner,
            AuthorSnapshot = SocialSeedAuthors.Beginner,
            PostType = PostType.Standard,
            Content = "Sáng nay chạy bộ 5km thời tiết tuyệt vời! Ai muốn join buổi sáng mai không?",
            MediaUrls = ["https://picsum.photos/seed/gym1/800/600"],
            IsPublic = true,
            ShareCode = "SYNCP001",
            Metrics = new PostMetrics { LikeCount = 24, CommentCount = 3, ShareCount = 2 },
            CreatedAt = utcNow.AddHours(-3),
        },
        new Post
        {
            Id = Post2Id,
            AuthorId = SocialSeedUserIds.ProAthlete,
            AuthorSnapshot = SocialSeedAuthors.ProAthlete,
            PostType = PostType.AchievementShare,
            Content = "Đã hoàn thành Phase 1 của Foundation roadmap 💪 Cảm giác thật tuyệt!",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SYNCP002",
            Metrics = new PostMetrics { LikeCount = 56, CommentCount = 8, ShareCount = 4 },
            CreatedAt = utcNow.AddHours(-6),
        },
        new Post
        {
            Id = Post3Id,
            AuthorId = SocialSeedUserIds.Nutritionist,
            AuthorSnapshot = SocialSeedAuthors.Nutritionist,
            PostType = PostType.Standard,
            Content = "Gợi ý bữa sáng trước khi tập tạ: yến mạch + trứng + chuối. Đủ carb chậm và protein cho buổi sáng năng lượng!",
            MediaUrls = ["https://picsum.photos/seed/meal1/800/600", "https://picsum.photos/seed/meal2/800/600"],
            IsPublic = true,
            ShareCode = "SYNCP003",
            Metrics = new PostMetrics { LikeCount = 41, CommentCount = 5, ShareCount = 6 },
            CreatedAt = utcNow.AddHours(-10),
        },
        new Post
        {
            Id = Post4Id,
            AuthorId = SocialSeedUserIds.ProAthlete,
            AuthorSnapshot = SocialSeedAuthors.ProAthlete,
            PostType = PostType.StreakShare,
            Content = "Kỷ lục mới: Deadlift 120kg! 🔥 Chuỗi tập 21 ngày không nghỉ.",
            MediaUrls = ["https://picsum.photos/seed/deadlift/800/600"],
            IsPublic = true,
            ShareCode = "SYNCP004",
            Metrics = new PostMetrics { LikeCount = 89, CommentCount = 12, ShareCount = 3 },
            CreatedAt = utcNow.AddHours(-14),
        },
        new Post
        {
            Id = Post5Id,
            AuthorId = SocialSeedUserIds.ActiveMember,
            AuthorSnapshot = SocialSeedAuthors.ActiveMember,
            PostType = PostType.Standard,
            Content = "Cardio zone 2 buổi chiều — 45 phút đạp xe trong nhà. Nhịp tim trung bình 135 bpm.",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SYNCP005",
            Metrics = new PostMetrics { LikeCount = 18, CommentCount = 2, ShareCount = 1 },
            CreatedAt = utcNow.AddHours(-18),
        },
        new Post
        {
            Id = Post6Id,
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            PostType = PostType.Standard,
            Content = "Mẹo từ đội SYNC: khởi động ít nhất 10 phút trước khi nâng tạ nặng để giảm chấn thương.",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SYNCP006",
            Metrics = new PostMetrics { LikeCount = 32, CommentCount = 4, ShareCount = 5 },
            CreatedAt = utcNow.AddHours(-22),
        },
        new Post
        {
            Id = Post7Id,
            AuthorId = SocialSeedUserIds.Beginner,
            AuthorSnapshot = SocialSeedAuthors.Beginner,
            PostType = PostType.AchievementShare,
            Content = "Tuần đầu tiên hoàn thành 3 buổi tập — mình không nghĩ mình làm được đâu!",
            MediaUrls = ["https://picsum.photos/seed/beginner/800/600"],
            IsPublic = true,
            ShareCode = "SYNCP007",
            Metrics = new PostMetrics { LikeCount = 15, CommentCount = 6, ShareCount = 0 },
            CreatedAt = utcNow.AddDays(-1),
        },
        new Post
        {
            Id = Post8Id,
            AuthorId = SocialSeedUserIds.Nutritionist,
            AuthorSnapshot = SocialSeedAuthors.Nutritionist,
            PostType = PostType.StreakShare,
            Content = "Chuỗi 14 ngày log macro đầy đủ — protein đủ, carb vừa phải, mỡ tốt. Ai cần template Excel inbox mình!",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SYNCP008",
            Metrics = new PostMetrics { LikeCount = 27, CommentCount = 3, ShareCount = 2 },
            CreatedAt = utcNow.AddDays(-1).AddHours(-4),
        },
        new Post
        {
            Id = Post9Id,
            AuthorId = SocialSeedUserIds.ActiveMember,
            AuthorSnapshot = SocialSeedAuthors.ActiveMember,
            PostType = PostType.Standard,
            Content = "Buổi HIIT 20 phút tại công viên Tao Đàn — mồ hôi nhễ nhại nhưng đáng giá!",
            MediaUrls =
            [
                "https://picsum.photos/seed/hiit1/800/600",
                "https://picsum.photos/seed/hiit2/800/600",
                "https://picsum.photos/seed/hiit3/800/600",
            ],
            IsPublic = true,
            ShareCode = "SYNCP009",
            Metrics = new PostMetrics { LikeCount = 36, CommentCount = 7, ShareCount = 1 },
            CreatedAt = utcNow.AddDays(-2),
        },
        new Post
        {
            Id = Post10Id,
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            PostType = PostType.ChallengeCreation,
            Content = "Thử thách 100km Tháng 6 đã mở đăng ký! Cùng SYNC chinh phục quãng đường này nhé 🏃",
            MediaUrls = [],
            ReferenceId = ChallengeActiveId,
            IsPublic = true,
            ShareCode = "SYNCP010",
            Metrics = new PostMetrics { LikeCount = 62, CommentCount = 9, ShareCount = 8 },
            CreatedAt = utcNow.AddDays(-2).AddHours(-6),
        },
    ];

    /// <summary>10 stories: 4 video, 4 image, 2 text-only — 5 active + 5 expired.</summary>
    public static IReadOnlyList<Story> GetSeedStories(DateTimeOffset utcNow) =>
    [
        // ── Active (5) — ExpiresAt +12h ──────────────────────────────────────
        new Story
        {
            Id = Guid.Parse("c4000001-0000-0000-0000-000000000001"),
            AuthorId = SocialSeedUserIds.ProAthlete,
            AuthorSnapshot = SocialSeedAuthors.ProAthlete,
            MediaUrl = "https://sync-assets.com/stories/squat-form.mp4",
            MediaType = StoryMediaType.Video,
            Caption = "Form squat chuẩn — góc quay side view",
            ExpiresAt = utcNow.AddHours(12),
            ViewCount = 48,
            LikeCount = 12,
            IsActive = true,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-4),
        },
        new Story
        {
            Id = Guid.Parse("c4000002-0000-0000-0000-000000000002"),
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            MediaUrl = "https://sync-assets.com/stories/warmup-routine.mp4",
            MediaType = StoryMediaType.Video,
            Caption = "Khởi động 5 phút trước buổi tập",
            ExpiresAt = utcNow.AddHours(12),
            ViewCount = 31,
            LikeCount = 7,
            IsActive = true,
            Privacy = PrivacyType.Followers,
            CreatedAt = utcNow.AddHours(-5),
        },
        new Story
        {
            Id = Guid.Parse("c4000003-0000-0000-0000-000000000003"),
            AuthorId = SocialSeedUserIds.Beginner,
            AuthorSnapshot = SocialSeedAuthors.Beginner,
            MediaUrl = "https://picsum.photos/seed/story-run/1080/1920.jpg",
            MediaType = StoryMediaType.Image,
            Caption = "Buổi chạy sáng đầu tiên 3km không dừng!",
            ExpiresAt = utcNow.AddHours(12),
            ViewCount = 19,
            LikeCount = 4,
            IsActive = true,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-3),
        },
        new Story
        {
            Id = Guid.Parse("c4000004-0000-0000-0000-000000000004"),
            AuthorId = SocialSeedUserIds.Nutritionist,
            AuthorSnapshot = SocialSeedAuthors.Nutritionist,
            MediaUrl = "https://picsum.photos/seed/story-salad/1080/1920.jpg",
            MediaType = StoryMediaType.Image,
            Caption = "Salad protein sau buổi tập",
            ExpiresAt = utcNow.AddHours(12),
            ViewCount = 37,
            LikeCount = 11,
            IsActive = true,
            Privacy = PrivacyType.Followers,
            CreatedAt = utcNow.AddHours(-6),
        },
        new Story
        {
            Id = Guid.Parse("c4000005-0000-0000-0000-000000000005"),
            AuthorId = SocialSeedUserIds.ActiveMember,
            AuthorSnapshot = SocialSeedAuthors.ActiveMember,
            MediaUrl = string.Empty,
            MediaType = StoryMediaType.TextOnly,
            Caption = "Rest day is important! Cơ bắp phát triển khi nghỉ ngơi.",
            ExpiresAt = utcNow.AddHours(12),
            ViewCount = 14,
            LikeCount = 3,
            IsActive = true,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-2),
        },

        // ── Expired (5) — ExpiresAt -5h, IsActive = false ───────────────────
        new Story
        {
            Id = Guid.Parse("c4000006-0000-0000-0000-000000000006"),
            AuthorId = SocialSeedUserIds.ProAthlete,
            AuthorSnapshot = SocialSeedAuthors.ProAthlete,
            MediaUrl = "https://sync-assets.com/stories/cycling-interval.mp4",
            MediaType = StoryMediaType.Video,
            Caption = "Interval đạp xe 30s on / 30s off",
            ExpiresAt = utcNow.AddHours(-5),
            ViewCount = 102,
            LikeCount = 24,
            IsActive = false,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-28),
        },
        new Story
        {
            Id = Guid.Parse("c4000007-0000-0000-0000-000000000007"),
            AuthorId = SocialSeedUserIds.ActiveMember,
            AuthorSnapshot = SocialSeedAuthors.ActiveMember,
            MediaUrl = "https://sync-assets.com/stories/expired-hiit.mp4",
            MediaType = StoryMediaType.Video,
            Caption = "HIIT 15 phút full body",
            ExpiresAt = utcNow.AddHours(-5),
            ViewCount = 51,
            LikeCount = 10,
            IsActive = false,
            Privacy = PrivacyType.Followers,
            CreatedAt = utcNow.AddHours(-29),
        },
        new Story
        {
            Id = Guid.Parse("c4000008-0000-0000-0000-000000000008"),
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            MediaUrl = "https://picsum.photos/seed/story-gym/1080/1920.jpg",
            MediaType = StoryMediaType.Image,
            Caption = "Leg day done ✅",
            ExpiresAt = utcNow.AddHours(-5),
            ViewCount = 67,
            LikeCount = 15,
            IsActive = false,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-30),
        },
        new Story
        {
            Id = Guid.Parse("c4000009-0000-0000-0000-000000000009"),
            AuthorId = SocialSeedUserIds.Beginner,
            AuthorSnapshot = SocialSeedAuthors.Beginner,
            MediaUrl = "https://picsum.photos/seed/expired2/1080/1920.jpg",
            MediaType = StoryMediaType.Image,
            Caption = "Ngày đầu vào phòng gym",
            ExpiresAt = utcNow.AddHours(-5),
            ViewCount = 33,
            LikeCount = 6,
            IsActive = false,
            Privacy = PrivacyType.Public,
            CreatedAt = utcNow.AddHours(-27),
        },
        new Story
        {
            Id = Guid.Parse("c4000010-0000-0000-0000-000000000010"),
            AuthorId = SocialSeedUserIds.Nutritionist,
            AuthorSnapshot = SocialSeedAuthors.Nutritionist,
            MediaUrl = string.Empty,
            MediaType = StoryMediaType.TextOnly,
            Caption = "Hydration matters — uống 500ml nước ngay khi thức dậy.",
            ExpiresAt = utcNow.AddHours(-5),
            ViewCount = 44,
            LikeCount = 8,
            IsActive = false,
            Privacy = PrivacyType.Followers,
            CreatedAt = utcNow.AddHours(-26),
        },
    ];

    public static IReadOnlyList<CommunityChallenge> GetSeedCommunityChallenges(DateTimeOffset utcNow) =>
    [
        BuildSeedChallenge(
            id: ChallengeActiveId,
            creatorId: SocialSeedUserIds.Admin,
            title: "Thử thách 100km Tháng 6",
            description: "Cùng nhau chạy/đạp tổng 100km trong tháng 6. Hoàn thành để nhận 500 điểm SYNC!",
            createdAt: utcNow.AddDays(-20),
            registrationDeadline: utcNow.AddDays(-10),
            startDate: utcNow.AddDays(-5),
            endDate: utcNow.AddDays(25),
            goalType: ChallengeGoalType.TotalDistance,
            targetValue: 100,
            pointRewards: 500,
            gifts: ["Badge 100K", "Áo thun SYNC"],
            address: "Công viên Tao Đàn, Quận 1, TP.HCM",
            location: HcmLocation(),
            participantCount: 5,
            utcNow),
        BuildSeedChallenge(
            id: ChallengeUpcomingId,
            creatorId: SocialSeedUserIds.Nutritionist,
            title: "Thử thách Đốt mỡ 5000 Kcal",
            description: "Đốt cháy 5000 kcal trong 30 ngày thông qua cardio và strength training.",
            createdAt: utcNow.AddDays(-3),
            registrationDeadline: utcNow.AddDays(10),
            startDate: utcNow.AddDays(14),
            endDate: utcNow.AddDays(44),
            goalType: ChallengeGoalType.TotalCaloriesBurned,
            targetValue: 5000,
            pointRewards: 400,
            gifts: ["Shaker SYNC"],
            address: "Landmark 81, Bình Thạnh, TP.HCM",
            location: new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
                new GeoJson2DGeographicCoordinates(106.7220, 10.7951)),
            participantCount: 0,
            utcNow),
        BuildSeedChallenge(
            id: ChallengeUpcomingWaitingId,
            creatorId: SocialSeedUserIds.ProAthlete,
            title: "Sprint 21 Ngày Core",
            description: "21 ngày tập core — đăng ký đã đóng, chờ ngày bắt đầu.",
            createdAt: utcNow.AddDays(-14),
            registrationDeadline: utcNow.AddDays(-2),
            startDate: utcNow.AddDays(7),
            endDate: utcNow.AddDays(28),
            goalType: ChallengeGoalType.TotalWorkouts,
            targetValue: 21,
            pointRewards: 350,
            gifts: ["Badge Core"],
            address: "Sân vận động Thống Nhất, TP.HCM",
            location: new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
                new GeoJson2DGeographicCoordinates(106.6688, 10.8003)),
            participantCount: 12,
            utcNow),
        BuildSeedChallenge(
            id: ChallengeCompletedId,
            creatorId: SocialSeedUserIds.Admin,
            title: "Chuỗi 14 ngày Workout",
            description: "Tập luyện liên tục 14 ngày — không bỏ lỡ một buổi nào!",
            createdAt: utcNow.AddMonths(-2),
            registrationDeadline: utcNow.AddDays(-45),
            startDate: utcNow.AddDays(-40),
            endDate: utcNow.AddDays(-14),
            goalType: ChallengeGoalType.TotalWorkouts,
            targetValue: 14,
            pointRewards: 300,
            gifts: ["Voucher 200k"],
            address: "SYNC Fitness Hub, Quận 7, TP.HCM",
            location: new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
                new GeoJson2DGeographicCoordinates(106.7204, 10.7295)),
            participantCount: 4,
            utcNow),
    ];

    private static CommunityChallenge BuildSeedChallenge(
        Guid id,
        Guid creatorId,
        string title,
        string description,
        DateTimeOffset createdAt,
        DateTimeOffset registrationDeadline,
        DateTimeOffset startDate,
        DateTimeOffset endDate,
        ChallengeGoalType goalType,
        decimal targetValue,
        decimal pointRewards,
        string[] gifts,
        string address,
        GeoJsonPoint<GeoJson2DGeographicCoordinates> location,
        int participantCount,
        DateTimeOffset utcNow)
    {
        var challenge = new CommunityChallenge
        {
            Id = id,
            CreatorId = creatorId,
            Title = title,
            Description = description,
            RegistrationDeadline = registrationDeadline,
            StartDate = startDate,
            EndDate = endDate,
            GoalType = goalType,
            TargetValue = targetValue,
            PointRewards = pointRewards,
            Gifts = gifts,
            Address = address,
            Location = location,
            ParticipantCount = participantCount,
            CreatedAt = createdAt,
        };

        challenge.Status = ChallengeStatusResolver.Resolve(challenge, utcNow);
        return challenge;
    }

    public static IReadOnlyList<ChallengeParticipant> GetSeedChallengeParticipants(DateTimeOffset utcNow) =>
    [
        // Active 100km — InProgress (~45.5 km equivalent progress via status)
        new ChallengeParticipant
        {
            Id = Guid.Parse("c7000001-0000-0000-0000-000000000001"),
            ChallengeId = ChallengeActiveId,
            UserId = SocialSeedUserIds.ProAthlete,
            Status = ParticipantStatus.InProgress,
            JoinedAt = utcNow.AddDays(-4),
            IsActive = true,
            CreatedAt = utcNow.AddDays(-4),
        },
        new ChallengeParticipant
        {
            Id = Guid.Parse("c7000002-0000-0000-0000-000000000002"),
            ChallengeId = ChallengeActiveId,
            UserId = SocialSeedUserIds.ActiveMember,
            Status = ParticipantStatus.InProgress,
            JoinedAt = utcNow.AddDays(-3),
            IsActive = true,
            CreatedAt = utcNow.AddDays(-3),
        },
        new ChallengeParticipant
        {
            Id = Guid.Parse("c7000003-0000-0000-0000-000000000003"),
            ChallengeId = ChallengeActiveId,
            UserId = SocialSeedUserIds.Beginner,
            Status = ParticipantStatus.Joined,
            JoinedAt = utcNow.AddDays(-1),
            IsActive = true,
            CreatedAt = utcNow.AddDays(-1),
        },
        // Completed challenge — finished participants
        new ChallengeParticipant
        {
            Id = Guid.Parse("c7000004-0000-0000-0000-000000000004"),
            ChallengeId = ChallengeCompletedId,
            UserId = SocialSeedUserIds.ProAthlete,
            Status = ParticipantStatus.Completed,
            JoinedAt = utcNow.AddMonths(-1),
            CompletedAt = utcNow.AddDays(-15),
            IsActive = true,
            CreatedAt = utcNow.AddMonths(-1),
        },
        new ChallengeParticipant
        {
            Id = Guid.Parse("c7000005-0000-0000-0000-000000000005"),
            ChallengeId = ChallengeCompletedId,
            UserId = SocialSeedUserIds.Beginner,
            Status = ParticipantStatus.Dropped,
            JoinedAt = utcNow.AddMonths(-1).AddDays(2),
            CompletedAt = null,
            IsActive = false,
            CreatedAt = utcNow.AddMonths(-1).AddDays(2),
        },
    ];

    public static IReadOnlyList<Blog> GetSeedBlogs(DateTimeOffset utcNow) =>
    [
        new Blog
        {
            Id = Guid.Parse("c5000001-0000-0000-0000-000000000001"),
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            Title = "Hướng dẫn hít thở đúng cách khi tập tạ",
            Slug = "hit-tho-dung-cach",
            CoverImageUrl = "https://picsum.photos/seed/blog-breath/1200/630.jpg",
            Content = """
                <h2>Nguyên tắc cơ bản</h2>
                <p>Hạ tạ: hít vào — đẩy tạ: thở ra. Giữ core căng trong suốt rep.</p>
                <h3>Lỗi thường gặp</h3>
                <ul><li>Nín thở khi squat</li><li>Thở quá nhanh khi deadlift</li></ul>
                """,
            Tags = ["strength", "breathing", "beginner"],
            Status = BlogStatus.Published,
            PublishedAt = utcNow.AddDays(-10),
            LikeCount = 45,
            ShareCount = 12,
            CreatedAt = utcNow.AddDays(-12),
        },
        new Blog
        {
            Id = Guid.Parse("c5000002-0000-0000-0000-000000000002"),
            AuthorId = SocialSeedUserIds.Nutritionist,
            AuthorSnapshot = SocialSeedAuthors.Nutritionist,
            Title = "Chế độ ăn Keto có thực sự tốt cho người tập Gym?",
            Slug = "an-keto-tap-gym",
            CoverImageUrl = "https://picsum.photos/seed/blog-keto/1200/630.jpg",
            Content = """
                <p>Keto giảm carb xuống dưới 50g/ngày. Với người tập gym, cần cân nhắc:</p>
                <p><strong>Ưu điểm:</strong> kiểm soát cân nặng nhanh, ổn định đường huyết.</p>
                <p><strong>Nhược điểm:</strong> giảm hiệu suất tập nặng giai đoạn đầu.</p>
                """,
            Tags = ["nutrition", "keto", "gym"],
            Status = BlogStatus.Published,
            PublishedAt = utcNow.AddDays(-5),
            LikeCount = 38,
            ShareCount = 9,
            CreatedAt = utcNow.AddDays(-7),
        },
        new Blog
        {
            Id = Guid.Parse("c5000003-0000-0000-0000-000000000003"),
            AuthorId = SocialSeedUserIds.ProAthlete,
            AuthorSnapshot = SocialSeedAuthors.ProAthlete,
            Title = "Giáo án 4 ngày/tuần cho người mới bắt đầu",
            Slug = "giao-an-4-ngay",
            CoverImageUrl = "https://picsum.photos/seed/blog-plan/1200/630.jpg",
            Content = """
                ## Tuần 1–4
                - **Thứ 2:** Upper body
                - **Thứ 4:** Lower body
                - **Thứ 6:** Full body
                - **Thứ 7:** Cardio nhẹ 30 phút
                """,
            Tags = ["workout-plan", "beginner", "4-day-split"],
            Status = BlogStatus.Draft,
            PublishedAt = null,
            LikeCount = 0,
            ShareCount = 0,
            CreatedAt = utcNow.AddDays(-3),
        },
    ];

    public static IReadOnlyList<UserFollow> GetSeedUserFollows(DateTimeOffset utcNow) =>
    [
        Follow(SocialSeedUserIds.Beginner, SocialSeedUserIds.Admin, utcNow.AddDays(-20), "c6000001-0000-0000-0000-000000000001"),
        Follow(SocialSeedUserIds.Beginner, SocialSeedUserIds.ProAthlete, utcNow.AddDays(-18), "c6000002-0000-0000-0000-000000000002"),
        Follow(SocialSeedUserIds.ActiveMember, SocialSeedUserIds.Admin, utcNow.AddDays(-15), "c6000003-0000-0000-0000-000000000003"),
        Follow(SocialSeedUserIds.ActiveMember, SocialSeedUserIds.Nutritionist, utcNow.AddDays(-14), "c6000004-0000-0000-0000-000000000004"),
        Follow(SocialSeedUserIds.Nutritionist, SocialSeedUserIds.ProAthlete, utcNow.AddDays(-12), "c6000005-0000-0000-0000-000000000005"),
        Follow(SocialSeedUserIds.ProAthlete, SocialSeedUserIds.Admin, utcNow.AddDays(-10), "c6000006-0000-0000-0000-000000000006"),
        Follow(SocialSeedUserIds.Admin, SocialSeedUserIds.ProAthlete, utcNow.AddDays(-9), "c6000007-0000-0000-0000-000000000007"),
        Follow(SocialSeedUserIds.Beginner, SocialSeedUserIds.Nutritionist, utcNow.AddDays(-8), "c6000008-0000-0000-0000-000000000008"),
        Follow(SocialSeedUserIds.ActiveMember, SocialSeedUserIds.ProAthlete, utcNow.AddDays(-6), "c6000009-0000-0000-0000-000000000009"),
        Follow(SocialSeedUserIds.ProAthlete, SocialSeedUserIds.Nutritionist, utcNow.AddDays(-5), "c6000010-0000-0000-0000-000000000010"),
    ];

    public static IReadOnlyList<Comment> GetSeedComments(DateTimeOffset utcNow) =>
    [
        Comment(Post1Id, SocialSeedUserIds.ProAthlete, "Chạy 5km sáng nay đẹp thật! Mai mình join.", SocialSeedAuthors.ProAthlete, utcNow.AddHours(-2), "c2000001-0000-0000-0000-000000000001"),
        Comment(Post1Id, SocialSeedUserIds.Admin, "Cố lên bạn mới! 💪", SocialSeedAuthors.Admin, utcNow.AddHours(-1), "c2000002-0000-0000-0000-000000000002"),
        Comment(Post2Id, SocialSeedUserIds.Beginner, "Phase 1 xong rồi — inspire quá!", SocialSeedAuthors.Beginner, utcNow.AddHours(-5), "c2000003-0000-0000-0000-000000000003"),
        Comment(Post3Id, SocialSeedUserIds.ActiveMember, "Đã thử combo này, no lâu và tập tốt hơn.", SocialSeedAuthors.ActiveMember, utcNow.AddHours(-9), "c2000004-0000-0000-0000-000000000004"),
        Comment(Post4Id, SocialSeedUserIds.Admin, "120kg deadlift — form video đi!", SocialSeedAuthors.Admin, utcNow.AddHours(-13), "c2000005-0000-0000-0000-000000000005"),
        Comment(Post4Id, SocialSeedUserIds.Beginner, "Mục tiêu của mình là 80kg thôi 😅", SocialSeedAuthors.Beginner, utcNow.AddHours(-12), "c2000006-0000-0000-0000-000000000006"),
        Comment(Post6Id, SocialSeedUserIds.ProAthlete, "Khởi động hip mobility 5 phút nữa thì perfect.", SocialSeedAuthors.ProAthlete, utcNow.AddHours(-21), "c2000007-0000-0000-0000-000000000007"),
        Comment(Post7Id, SocialSeedUserIds.Nutritionist, "Tuần đầu là khó nhất — bạn làm tốt lắm!", SocialSeedAuthors.Nutritionist, utcNow.AddDays(-1), "c2000008-0000-0000-0000-000000000008"),
        Comment(Post9Id, SocialSeedUserIds.Beginner, "HIIT ngoài trời thích hơn phòng gym!", SocialSeedAuthors.Beginner, utcNow.AddDays(-2), "c2000009-0000-0000-0000-000000000009"),
        Comment(Post10Id, SocialSeedUserIds.ActiveMember, "Đã đăng ký thử thách 100km!", SocialSeedAuthors.ActiveMember, utcNow.AddDays(-2), "c2000010-0000-0000-0000-000000000010"),
    ];

    public static IReadOnlyList<Interaction> GetSeedInteractions(DateTimeOffset utcNow) =>
    [
        Like(Post1Id, SocialSeedUserIds.Admin, utcNow.AddHours(-2), "c3000001-0000-0000-0000-000000000001"),
        Like(Post1Id, SocialSeedUserIds.ProAthlete, utcNow.AddHours(-2), "c3000002-0000-0000-0000-000000000002"),
        Share(Post1Id, SocialSeedUserIds.ActiveMember, utcNow.AddHours(-1), "c3000003-0000-0000-0000-000000000003"),

        Like(Post2Id, SocialSeedUserIds.Beginner, utcNow.AddHours(-5), "c3000004-0000-0000-0000-000000000004"),
        Like(Post2Id, SocialSeedUserIds.Admin, utcNow.AddHours(-5), "c3000005-0000-0000-0000-000000000005"),
        Share(Post2Id, SocialSeedUserIds.Nutritionist, utcNow.AddHours(-4), "c3000006-0000-0000-0000-000000000006"),

        Like(Post3Id, SocialSeedUserIds.ProAthlete, utcNow.AddHours(-9), "c3000007-0000-0000-0000-000000000007"),
        Like(Post4Id, SocialSeedUserIds.ActiveMember, utcNow.AddHours(-13), "c3000008-0000-0000-0000-000000000008"),
        Share(Post4Id, SocialSeedUserIds.Beginner, utcNow.AddHours(-12), "c3000009-0000-0000-0000-000000000009"),

        Like(Post6Id, SocialSeedUserIds.Beginner, utcNow.AddHours(-21), "c3000010-0000-0000-0000-000000000010"),
        Like(Post7Id, SocialSeedUserIds.Admin, utcNow.AddDays(-1), "c3000011-0000-0000-0000-000000000011"),
        Share(Post9Id, SocialSeedUserIds.ProAthlete, utcNow.AddDays(-2), "c3000012-0000-0000-0000-000000000012"),

        Like(Post10Id, SocialSeedUserIds.Beginner, utcNow.AddDays(-2), "c3000013-0000-0000-0000-000000000013"),
        Like(Post10Id, SocialSeedUserIds.ActiveMember, utcNow.AddDays(-2), "c3000014-0000-0000-0000-000000000014"),
        Share(Post10Id, SocialSeedUserIds.Nutritionist, utcNow.AddDays(-1), "c3000015-0000-0000-0000-000000000015"),
    ];

    // ─── Legacy aliases (existing seeder) ───────────────────────────────────
    public static IReadOnlyList<Post> GetPosts(DateTimeOffset utcNow) => GetSeedPosts(utcNow);
    public static IReadOnlyList<Comment> GetComments(DateTimeOffset utcNow) => GetSeedComments(utcNow);
    public static IReadOnlyList<Interaction> GetInteractions(DateTimeOffset utcNow) => GetSeedInteractions(utcNow);
    public static IReadOnlyList<CommunityChallenge> GetCommunityChallenges(DateTimeOffset utcNow) =>
        GetSeedCommunityChallenges(utcNow);

    private static UserFollow Follow(Guid follower, Guid followee, DateTimeOffset followedAt, string id) =>
        new()
        {
            Id = Guid.Parse(id),
            FollowerId = follower,
            FolloweeId = followee,
            FollowedAt = followedAt,
            Status = FollowStatus.Accepted,
            CreatedAt = followedAt,
        };

    private static Comment Comment(
        Guid postId,
        Guid userId,
        string content,
        AuthorSnapshot author,
        DateTimeOffset createdAt,
        string id) =>
        new()
        {
            Id = Guid.Parse(id),
            PostId = postId,
            UserId = userId,
            Content = content,
            AuthorSnapshot = author,
            CreatedAt = createdAt,
        };

    private static Interaction Like(Guid postId, Guid userId, DateTimeOffset createdAt, string id) =>
        new()
        {
            Id = Guid.Parse(id),
            PostId = postId,
            UserId = userId,
            InteractionType = InteractionType.Like,
            CreatedAt = createdAt,
        };

    private static Interaction Share(Guid postId, Guid userId, DateTimeOffset createdAt, string id) =>
        new()
        {
            Id = Guid.Parse(id),
            PostId = postId,
            UserId = userId,
            InteractionType = InteractionType.Share,
            CreatedAt = createdAt,
        };
}
