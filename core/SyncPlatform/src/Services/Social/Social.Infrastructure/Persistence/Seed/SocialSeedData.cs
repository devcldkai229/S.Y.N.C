using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Infrastructure.Persistence.Seed;

public static class SocialSeedData
{
    public static readonly Guid SeedMarkerPostId = Guid.Parse("c1000001-0000-0000-0000-000000000001");

    public static readonly Guid CommunityChallengeId = Guid.Parse("c8000001-0000-0000-0000-000000000001");

    public static readonly Guid PostDemoWelcomeId = SeedMarkerPostId;
    public static readonly Guid PostDemoGalleryId = Guid.Parse("c1000002-0000-0000-0000-000000000002");
    public static readonly Guid PostDemoAchievementId = Guid.Parse("c1000003-0000-0000-0000-000000000003");
    public static readonly Guid PostDemoStreakId = Guid.Parse("c1000004-0000-0000-0000-000000000004");
    public static readonly Guid PostDemoPrivateId = Guid.Parse("c1000005-0000-0000-0000-000000000005");
    public static readonly Guid PostAdminTipId = Guid.Parse("c1000006-0000-0000-0000-000000000006");
    public static readonly Guid PostAdminPhotoId = Guid.Parse("c1000007-0000-0000-0000-000000000007");
    public static readonly Guid PostPartnerWorkoutId = Guid.Parse("c1000008-0000-0000-0000-000000000008");
    public static readonly Guid PostPartnerChallengeId = Guid.Parse("c1000009-0000-0000-0000-000000000009");
    public static readonly Guid PostDemoOlderId = Guid.Parse("c1000010-0000-0000-0000-000000000010");

    public static IReadOnlyList<CommunityChallenge> GetCommunityChallenges(DateTimeOffset utcNow) =>
    [
        new CommunityChallenge
        {
            Id = CommunityChallengeId,
            CreatorId = SocialSeedUserIds.Partner,
            Title = "Chạy 50km tháng này",
            Description = "Cùng nhau chạy đủ 50km trong 30 ngày — ai hoàn thành nhận badge đặc biệt!",
            StartDate = utcNow.AddDays(-5),
            EndDate = utcNow.AddDays(25),
            GoalType = ChallengeGoalType.TotalDistance,
            TargetValue = 50,
            ParticipantCount = 12,
            Status = ChallengeStatus.Active,
        },
    ];

    public static IReadOnlyList<Post> GetPosts(DateTimeOffset utcNow) =>
    [
        new Post
        {
            Id = PostDemoWelcomeId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.Standard,
            Content = "Chào cộng đồng SYNC! Mình vừa bắt đầu hành trình giảm mỡ 12 tuần 💪",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SEDEMO01",
            Metrics = new PostMetrics { LikeCount = 3, CommentCount = 3, ShareCount = 1 },
            CreatedAt = utcNow.AddHours(-2),
        },
        new Post
        {
            Id = PostDemoGalleryId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.Standard,
            Content = "Buổi sáng nay tại công viên — năng lượng tuyệt vời!",
            MediaUrls =
            [
                "https://cdn.sync.local/social/demo-run-1.jpg",
                "https://cdn.sync.local/social/demo-run-2.jpg",
            ],
            IsPublic = true,
            ShareCode = "SEDEMO02",
            Metrics = new PostMetrics { LikeCount = 2, CommentCount = 1, ShareCount = 0 },
            CreatedAt = utcNow.AddHours(-8),
        },
        new Post
        {
            Id = PostDemoAchievementId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.AchievementShare,
            Content = "Vừa mở khóa thành tích Chuỗi 7 ngày! 🔥",
            MediaUrls = ["https://cdn.sync.local/social/achievement-streak7.png"],
            IsPublic = true,
            ShareCode = "SEDEMO03",
            Metrics = new PostMetrics { LikeCount = 3, CommentCount = 2, ShareCount = 1 },
            CreatedAt = utcNow.AddHours(-20),
        },
        new Post
        {
            Id = PostDemoStreakId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.StreakShare,
            Content = "Streak 7 ngày và đang tiến tới level 6!",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SEDEMO04",
            Metrics = new PostMetrics { LikeCount = 1, CommentCount = 0, ShareCount = 0 },
            CreatedAt = utcNow.AddDays(-1),
        },
        new Post
        {
            Id = PostDemoPrivateId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.Standard,
            Content = "Ghi chú riêng: hôm nay hơi mệt, mai giảm intensity.",
            MediaUrls = [],
            IsPublic = false,
            ShareCode = "SEDEMO05",
            Metrics = new PostMetrics { LikeCount = 0, CommentCount = 0, ShareCount = 0 },
            CreatedAt = utcNow.AddHours(-4),
        },
        new Post
        {
            Id = PostAdminTipId,
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            PostType = PostType.Standard,
            Content = "Mẹo từ đội SYNC: uống đủ nước trước buổi cardio ít nhất 500ml.",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SEADMIN1",
            Metrics = new PostMetrics { LikeCount = 2, CommentCount = 1, ShareCount = 0 },
            CreatedAt = utcNow.AddHours(-6),
        },
        new Post
        {
            Id = PostAdminPhotoId,
            AuthorId = SocialSeedUserIds.Admin,
            AuthorSnapshot = SocialSeedAuthors.Admin,
            PostType = PostType.Standard,
            Content = "Behind the scenes — team SYNC đang test tính năng feed mới.",
            MediaUrls = ["https://cdn.sync.local/social/admin-team.jpg"],
            IsPublic = true,
            ShareCode = "SEADMIN2",
            Metrics = new PostMetrics { LikeCount = 1, CommentCount = 0, ShareCount = 0 },
            CreatedAt = utcNow.AddHours(-12),
        },
        new Post
        {
            Id = PostPartnerWorkoutId,
            AuthorId = SocialSeedUserIds.Partner,
            AuthorSnapshot = SocialSeedAuthors.Partner,
            PostType = PostType.Standard,
            Content = "Leg day xong — 4x15 squat @ 60kg. Ai muốn join template HIIT của mình không?",
            MediaUrls = ["https://cdn.sync.local/social/partner-legday.jpg"],
            IsPublic = true,
            ShareCode = "SEPART01",
            Metrics = new PostMetrics { LikeCount = 3, CommentCount = 2, ShareCount = 1 },
            CreatedAt = utcNow.AddHours(-10),
        },
        new Post
        {
            Id = PostPartnerChallengeId,
            AuthorId = SocialSeedUserIds.Partner,
            AuthorSnapshot = SocialSeedAuthors.Partner,
            PostType = PostType.ChallengeCreation,
            Content = "Mình vừa tạo thử thách Chạy 50km tháng này — tham gia ngay nhé!",
            MediaUrls = [],
            ReferenceId = CommunityChallengeId,
            IsPublic = true,
            ShareCode = "SEPART02",
            Metrics = new PostMetrics { LikeCount = 2, CommentCount = 1, ShareCount = 2 },
            CreatedAt = utcNow.AddHours(-14),
        },
        new Post
        {
            Id = PostDemoOlderId,
            AuthorId = SocialSeedUserIds.Demo,
            AuthorSnapshot = SocialSeedAuthors.Demo,
            PostType = PostType.Standard,
            Content = "Tuần đầu tiên trên SYNC — đã quen với lịch tập sáng.",
            MediaUrls = [],
            IsPublic = true,
            ShareCode = "SEDEMO10",
            Metrics = new PostMetrics { LikeCount = 0, CommentCount = 1, ShareCount = 0 },
            CreatedAt = utcNow.AddDays(-3),
        },
    ];

    public static IReadOnlyList<Comment> GetComments(DateTimeOffset utcNow) =>
    [
        new Comment
        {
            Id = Guid.Parse("c2000001-0000-0000-0000-000000000001"),
            PostId = PostDemoWelcomeId,
            UserId = SocialSeedUserIds.Admin,
            Content = "Chào mừng bạn! Cố lên nhé 💪",
            AuthorSnapshot = SocialSeedAuthors.Admin,
            CreatedAt = utcNow.AddHours(-1),
        },
        new Comment
        {
            Id = Guid.Parse("c2000002-0000-0000-0000-000000000002"),
            PostId = PostDemoWelcomeId,
            UserId = SocialSeedUserIds.Partner,
            Content = "Hay quá, mình cũng đang cut!",
            AuthorSnapshot = SocialSeedAuthors.Partner,
            CreatedAt = utcNow.AddMinutes(-90),
        },
        new Comment
        {
            Id = Guid.Parse("c2000003-0000-0000-0000-000000000003"),
            PostId = PostDemoWelcomeId,
            UserId = SocialSeedUserIds.Demo,
            Content = "Cảm ơn mọi người đã động viên!",
            AuthorSnapshot = SocialSeedAuthors.Demo,
            CreatedAt = utcNow.AddMinutes(-60),
        },
        new Comment
        {
            Id = Guid.Parse("c2000004-0000-0000-0000-000000000004"),
            PostId = PostDemoGalleryId,
            UserId = SocialSeedUserIds.Partner,
            Content = "View đẹp quá!",
            AuthorSnapshot = SocialSeedAuthors.Partner,
            CreatedAt = utcNow.AddHours(-7),
        },
        new Comment
        {
            Id = Guid.Parse("c2000005-0000-0000-0000-000000000005"),
            PostId = PostDemoAchievementId,
            UserId = SocialSeedUserIds.Admin,
            Content = "Chúc mừng streak!",
            AuthorSnapshot = SocialSeedAuthors.Admin,
            CreatedAt = utcNow.AddHours(-18),
        },
        new Comment
        {
            Id = Guid.Parse("c2000006-0000-0000-0000-000000000006"),
            PostId = PostDemoAchievementId,
            UserId = SocialSeedUserIds.Partner,
            Content = "Level 5 rồi, giỏi!",
            AuthorSnapshot = SocialSeedAuthors.Partner,
            CreatedAt = utcNow.AddHours(-17),
        },
        new Comment
        {
            Id = Guid.Parse("c2000007-0000-0000-0000-000000000007"),
            PostId = PostAdminTipId,
            UserId = SocialSeedUserIds.Demo,
            Content = "Đúng rồi, mình hay quên uống nước 😅",
            AuthorSnapshot = SocialSeedAuthors.Demo,
            CreatedAt = utcNow.AddHours(-5),
        },
        new Comment
        {
            Id = Guid.Parse("c2000008-0000-0000-0000-000000000008"),
            PostId = PostPartnerWorkoutId,
            UserId = SocialSeedUserIds.Demo,
            Content = "Cho xin link template với!",
            AuthorSnapshot = SocialSeedAuthors.Demo,
            CreatedAt = utcNow.AddHours(-9),
        },
        new Comment
        {
            Id = Guid.Parse("c2000009-0000-0000-0000-000000000009"),
            PostId = PostPartnerWorkoutId,
            UserId = SocialSeedUserIds.Admin,
            Content = "Form squat chuẩn đấy.",
            AuthorSnapshot = SocialSeedAuthors.Admin,
            CreatedAt = utcNow.AddHours(-8),
        },
        new Comment
        {
            Id = Guid.Parse("c2000010-0000-0000-0000-000000000010"),
            PostId = PostPartnerChallengeId,
            UserId = SocialSeedUserIds.Demo,
            Content = "Đã join thử thách!",
            AuthorSnapshot = SocialSeedAuthors.Demo,
            CreatedAt = utcNow.AddHours(-13),
        },
        new Comment
        {
            Id = Guid.Parse("c2000011-0000-0000-0000-000000000011"),
            PostId = PostDemoOlderId,
            UserId = SocialSeedUserIds.Admin,
            Content = "Keep going!",
            AuthorSnapshot = SocialSeedAuthors.Admin,
            CreatedAt = utcNow.AddDays(-2),
        },
    ];

    public static IReadOnlyList<Interaction> GetInteractions(DateTimeOffset utcNow) =>
    [
        // PostDemoWelcome — 3 likes, 1 share
        Like(PostDemoWelcomeId, SocialSeedUserIds.Admin, utcNow.AddHours(-1), "c3000001-0000-0000-0000-000000000001"),
        Like(PostDemoWelcomeId, SocialSeedUserIds.Partner, utcNow.AddHours(-1), "c3000002-0000-0000-0000-000000000002"),
        Like(PostDemoWelcomeId, SocialSeedUserIds.Demo, utcNow.AddMinutes(-30), "c3000003-0000-0000-0000-000000000003"),
        Share(PostDemoWelcomeId, SocialSeedUserIds.Partner, utcNow.AddMinutes(-45), "c3000004-0000-0000-0000-000000000004"),

        // PostDemoGallery — 2 likes
        Like(PostDemoGalleryId, SocialSeedUserIds.Admin, utcNow.AddHours(-7), "c3000005-0000-0000-0000-000000000005"),
        Like(PostDemoGalleryId, SocialSeedUserIds.Partner, utcNow.AddHours(-6), "c3000006-0000-0000-0000-000000000006"),

        // PostDemoAchievement — 3 likes, 1 share
        Like(PostDemoAchievementId, SocialSeedUserIds.Admin, utcNow.AddHours(-19), "c3000007-0000-0000-0000-000000000007"),
        Like(PostDemoAchievementId, SocialSeedUserIds.Partner, utcNow.AddHours(-19), "c3000008-0000-0000-0000-000000000008"),
        Like(PostDemoAchievementId, SocialSeedUserIds.Demo, utcNow.AddHours(-18), "c3000009-0000-0000-0000-000000000009"),
        Share(PostDemoAchievementId, SocialSeedUserIds.Admin, utcNow.AddHours(-15), "c3000010-0000-0000-0000-000000000010"),

        // PostDemoStreak — 1 like
        Like(PostDemoStreakId, SocialSeedUserIds.Admin, utcNow.AddDays(-1), "c3000012-0000-0000-0000-000000000012"),

        // PostAdminTip — 2 likes
        Like(PostAdminTipId, SocialSeedUserIds.Demo, utcNow.AddHours(-5), "c3000013-0000-0000-0000-000000000013"),
        Like(PostAdminTipId, SocialSeedUserIds.Partner, utcNow.AddHours(-4), "c3000014-0000-0000-0000-000000000014"),

        // PostAdminPhoto — 1 like
        Like(PostAdminPhotoId, SocialSeedUserIds.Demo, utcNow.AddHours(-11), "c3000015-0000-0000-0000-000000000015"),

        // PostPartnerWorkout — 3 likes, 1 share
        Like(PostPartnerWorkoutId, SocialSeedUserIds.Demo, utcNow.AddHours(-9), "c3000016-0000-0000-0000-000000000016"),
        Like(PostPartnerWorkoutId, SocialSeedUserIds.Admin, utcNow.AddHours(-9), "c3000017-0000-0000-0000-000000000017"),
        Like(PostPartnerWorkoutId, SocialSeedUserIds.Partner, utcNow.AddHours(-8), "c3000018-0000-0000-0000-000000000018"),
        Share(PostPartnerWorkoutId, SocialSeedUserIds.Demo, utcNow.AddHours(-7), "c3000019-0000-0000-0000-000000000019"),

        // PostPartnerChallenge — 2 likes, 2 shares
        Like(PostPartnerChallengeId, SocialSeedUserIds.Demo, utcNow.AddHours(-13), "c3000020-0000-0000-0000-000000000020"),
        Like(PostPartnerChallengeId, SocialSeedUserIds.Admin, utcNow.AddHours(-12), "c3000021-0000-0000-0000-000000000021"),
        Share(PostPartnerChallengeId, SocialSeedUserIds.Demo, utcNow.AddHours(-12), "c3000022-0000-0000-0000-000000000022"),
        Share(PostPartnerChallengeId, SocialSeedUserIds.Admin, utcNow.AddHours(-11), "c3000023-0000-0000-0000-000000000023"),
    ];

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
