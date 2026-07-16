using Libs.Shared.Seed;
using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;
using Social.Application.Helpers;
using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Infrastructure.Persistence.Seed;

/// <summary>
/// Consolidated Social seed data — follow graph (120+ edges), 52 posts, stories, interactions,
/// challenges, blogs + static SeedAsync (merged from SocialDatabaseSeeder).
/// References SyncSeedUsers canonical GUIDs (§1 spec).
/// </summary>
public static class SocialSeedData
{
    // ─── Stable ID helpers ───────────────────────────────────────────────────
    // PostId:        d5{n:D6}-0000-4000-a000-000000000000
    // StoryId:       d6{n:D6}-0000-4000-a000-000000000000
    // FollowId:      d7{n:D6}-0000-4000-a000-000000000000
    // CommentId:     d4{pi:D2}{ci:D4}-0000-4000-a000-000000000000
    // InteractionId: d3{pi:D2}{ii:D4}-0000-4000-a000-000000000000

    private static Guid PostId(int n)    => Guid.Parse($"d5{n:D6}-0000-4000-a000-000000000000");
    private static Guid StoryId(int n)   => Guid.Parse($"d6{n:D6}-0000-4000-a000-000000000000");
    private static Guid FollowId(int n)  => Guid.Parse($"d7{n:D6}-0000-4000-a000-000000000000");
    private static Guid CommentId(int pi, int ci) =>
        Guid.Parse($"d4{pi:D2}{ci:D4}-0000-4000-a000-000000000000");
    private static Guid InteractionId(int pi, int ii) =>
        Guid.Parse($"d3{pi:D2}{ii:D4}-0000-4000-a000-000000000000");

    // ─── Author snapshots ────────────────────────────────────────────────────
    private static AuthorSnapshot Author(int nn)
    {
        var u = SyncSeedUsers.All.First(x => x.Nn == nn);
        return new AuthorSnapshot { FullName = u.FullName, AvatarUrl = SyncSeedUsers.AvatarUrl(u.Email) };
    }

    // ─── Challenge IDs (preserved for cross-reference with post seeds) ───────
    public static readonly Guid ChallengeActiveId          = Guid.Parse("c8000001-0000-0000-0000-000000000001");
    public static readonly Guid ChallengeUpcomingId        = Guid.Parse("c8000002-0000-0000-0000-000000000002");
    public static readonly Guid ChallengeCompletedId       = Guid.Parse("c8000003-0000-0000-0000-000000000003");
    public static readonly Guid ChallengeUpcomingWaitingId = Guid.Parse("c8000004-0000-0000-0000-000000000004");

    /// <summary>Idempotency marker — first seeded post.</summary>
    public static readonly Guid SeedMarkerPostId = PostId(1);

    public static IReadOnlyDictionary<Guid, string> ChallengeBackgroundUrls { get; } =
        new Dictionary<Guid, string>
        {
            [ChallengeActiveId]          = "https://vcdn1-kinhdoanh.vnecdn.net/2024/11/01/mb2-1982-1730427106.jpg?w=680&h=0&q=100&dpr=2&fit=crop&s=k1qrkshkJ-ChQadOU800KQ",
            [ChallengeUpcomingId]        = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT0gYoiVniv_39-D3L1G9bdQIYqASjaLCapOQ&s",
            [ChallengeUpcomingWaitingId] = "https://cdn.muscleandstrength.com/sites/default/files/field/feature-wide-image/workout/total_body_torcher_-_1000x500.jpg",
            [ChallengeCompletedId]       = "https://res.cloudinary.com/ggus-dev/image/private/s--sfLYWEsq--/c_auto,g_auto,w_3600,h_2400/v1/25fcf1e9/blog-10min-workout.webp?_a=BAAAV6DQ",
        };

    // Unsplash fitness/food image URLs
    private const string ImgGym1     = "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1080&q=80&auto=format";
    private const string ImgGym2     = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1080&q=80&auto=format";
    private const string ImgGym3     = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1080&q=80&auto=format";
    private const string ImgRun1     = "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=1080&q=80&auto=format";
    private const string ImgRun2     = "https://images.unsplash.com/photo-1461141346587-763ab02bced9?w=1080&q=80&auto=format";
    private const string ImgFood1    = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1080&q=80&auto=format";
    private const string ImgFood2    = "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=1080&q=80&auto=format";
    private const string ImgFood3    = "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1080&q=80&auto=format";
    private const string ImgProgress = "https://images.unsplash.com/photo-1550345332-09e3ac987658?w=1080&q=80&auto=format";

    // ─── Comment templates ────────────────────────────────────────────────────
    private static readonly string[] CommentTemplates =
    [
        "Đỉnh quá! Truyền cảm hứng cho mình lắm 💪",
        "Cho mình xin thực đơn / giáo án với!",
        "Cố lên bạn ơi, mình tin bạn làm được!",
        "Ngưỡng mộ sự kiên trì của bạn!",
        "Kết quả ấn tượng! Tập bao lâu vậy?",
        "Mình cũng đang theo lộ trình tương tự 🔥",
        "Bí quyết là gì vậy bạn?",
        "Hay quá, lưu lại để tham khảo!",
        "Bạn làm tốt lắm, tiếp tục nha!",
        "Thông tin hữu ích, cảm ơn bạn nhiều!",
        "Cho hỏi thêm về nutrition không?",
        "Progress nhanh vậy, method của bạn là gì?",
    ];

    // ─── 52 Posts ─────────────────────────────────────────────────────────────
    public static IReadOnlyList<Post> GetSeedPosts(DateTimeOffset utcNow)
    {
        var now = utcNow;
        return
        [
            // ── User 21 – Admin/Coach (5 posts) ──────────────────────────────
            P(1,  21, PostType.ChallengeCreation, "Thử thách 30 ngày Plank khởi động tuần tới! Mỗi ngày 1 phút — ai join cùng mình không? 💪", [ImgGym1], 18, 8, 4, now.AddDays(-1), ChallengeUpcomingWaitingId),
            P(2,  21, PostType.Standard, "Mẹo coach: Ngủ đủ 7-8 tiếng là yếu tố recovery quan trọng nhất. Không supplement nào thay thế được giấc ngủ!", [], 15, 6, 3, now.AddDays(-3)),
            P(3,  21, PostType.Standard, "Update roadmap AI mới: tự động đề xuất deload tuần khi phát hiện overreaching pattern 🔧 Anh em dùng thử nhé!", [], 16, 7, 5, now.AddDays(-5)),
            P(4,  21, PostType.AchievementShare, "SYNC cán mốc 1000 người dùng tích cực! Cảm ơn tất cả các bạn đã đồng hành 🙌🔥", [ImgProgress], 17, 9, 6, now.AddDays(-8)),
            P(5,  21, PostType.Standard, "Reminder: Warm-up đúng cách 10-15 phút giảm 40% nguy cơ chấn thương. Đừng skip dù mệt nhé!", [], 14, 5, 3, now.AddDays(-12)),

            // ── User 20 – KOL Dinh dưỡng (5 posts) ──────────────────────────
            P(6,  20, PostType.Standard, "Meal prep Chủ nhật: salad cá hồi + quinoa, 520 kcal/hộp 🥗 Ai muốn công thức inbox mình!", [ImgFood1, ImgFood2], 17, 7, 5, now.AddHours(-6)),
            P(7,  20, PostType.Standard, "Sự thật về ăn khuya: không phải giờ giấc mà là tổng calo trong ngày mới quan trọng. Vượt TDEE = tăng cân!", [], 15, 8, 4, now.AddDays(-2)),
            P(8,  20, PostType.AchievementShare, "Nhận chứng nhận Sports Nutrition Specialist từ ISSN! Tiếp tục học để phục vụ cộng đồng tốt hơn 📚", [ImgProgress], 16, 6, 9, now.AddDays(-6)),
            P(9,  20, PostType.Standard, "Top 5 thực phẩm tăng cơ tốt nhất KHÔNG cần supplement: Trứng, ức gà, cá hồi, cơm gạo lứt, sữa chua Hy Lạp 💯", [ImgFood3], 18, 9, 6, now.AddDays(-10)),
            P(10, 20, PostType.StreakShare, "33 ngày liên tục log đầy đủ macro 📊 Consistency mới là chìa khóa của mọi sự thay đổi!", [], 14, 5, 3, now.AddDays(-14)),

            // ── User 08 – Bodybuilder Advanced (5 posts) ─────────────────────
            P(11, 8, PostType.AchievementShare, "100 ngày không nghỉ 💪 STREAK_100 unlocked! Cảm ơn SYNC đã đồng hành suốt chặng đường này!", [ImgGym2], 18, 8, 4, now.AddHours(-4), referenceId: Guid.Parse("1e000001-0000-4000-a000-000000000000")),
            P(12, 8, PostType.StreakShare, "PR mới hôm nay: Deadlift 185kg × 3 rep! 🔥 Form video upload cuối tuần. Ai muốn xem?", [ImgGym1], 16, 7, 3, now.AddDays(-2)),
            P(13, 8, PostType.Standard, "Bulking season wrap-up: ăn 3300 kcal ổn định 8 tuần, lên 4kg lean mass, bodyfat chỉ tăng 1%. Quy trình 👇", [ImgGym3], 15, 6, 5, now.AddDays(-7)),
            P(14, 8, PostType.Standard, "Chest day: Bench 120kg × 5 / Incline DB 35kg × 10 / Cable fly 3×15. Volume cao nhất mùa 💯", [ImgGym2], 17, 9, 4, now.AddDays(-10)),
            P(15, 8, PostType.Standard, "Recovery sau leg day: 5 phút ice bath, foam roll kỹ glute + ham, ngủ trước 23h. Áp dụng được ngay!", [], 14, 6, 6, now.AddDays(-13)),

            // ── User 19 – Marathoner Advanced (4 posts) ──────────────────────
            P(16, 19, PostType.Standard, "Sáng chạy 18km interval — 6×3km @4:45/km. Body đang rất form! 🏃 Sub-4 đang đến gần.", [ImgRun1], 16, 6, 4, now.AddHours(-8)),
            P(17, 19, PostType.StreakShare, "Tuần 12 marathon prep: tổng 75km/tuần 🔥 Sub-4h hoàn toàn khả thi. Không bỏ cuộc!", [ImgRun2], 15, 5, 7, now.AddDays(-4)),
            P(18, 19, PostType.Standard, "Nutrition for endurance: gel mỗi 45 phút, uống điện giải từ km 10. Quên thì mất sức nhanh lắm.", [], 14, 5, 3, now.AddDays(-9)),
            P(19, 19, PostType.AchievementShare, "VM Half Marathon 2024: 2:04:22! 🎯 Kế hoạch tiếp theo: Full marathon sub-4h tháng 12!", [ImgRun1, ImgProgress], 17, 8, 5, now.AddDays(-15)),

            // ── User 04 – Recomp Advanced (5 posts) ──────────────────────────
            P(20, 4, PostType.Standard, "Recomp week 16: -3% bodyfat, +2kg lean. Data > cảm giác. SYNC AI optimize lịch tập rất chính xác.", [], 17, 7, 5, now.AddHours(-12)),
            P(21, 4, PostType.StreakShare, "63 ngày liên tục — không có ngày nào là 'quá khó'. Chỉ có ngày bạn chưa quyết tâm đủ. 🔥", [ImgProgress], 18, 9, 6, now.AddDays(-3)),
            P(22, 4, PostType.Standard, "Form check squat: hips back, chest up, knees track toes. Valgus knees = rủi ro cao. Sửa ngay!", [], 15, 6, 4, now.AddDays(-8)),
            P(23, 4, PostType.Standard, "Progressive overload không nhất thiết tăng tạ. Tăng rep, giảm rest, cải thiện form — đều count!", [], 14, 5, 4, now.AddDays(-11)),
            P(24, 4, PostType.Standard, "Fasted cardio 30p sáng + lifting chiều: HRV và recovery rate cải thiện rõ sau 4 tuần thử nghiệm.", [], 13, 5, 3, now.AddDays(-15)),

            // ── User 15 – Powerlifter Advanced (4 posts) ─────────────────────
            P(25, 15, PostType.Standard, "Squat day: 160kg × 5 × 3. Back squat cảm giác solid hơn tháng trước 💪 IPF total đang tiến!", [ImgGym3], 15, 6, 3, now.AddHours(-18)),
            P(26, 15, PostType.AchievementShare, "Top 3 giải powerlifting regional! 🥉 S:165 / B:110 / D:195 — tổng 470kg. Mùa sau target 500kg!", [ImgProgress], 17, 8, 4, now.AddDays(-5)),
            P(27, 15, PostType.Standard, "High bar vs Low bar squat: high bar kiểm soát mechanics tốt, low bar transfer strength nhiều hơn. Tuỳ mục đích!", [], 13, 5, 3, now.AddDays(-9)),
            P(28, 15, PostType.Standard, "Wrist mobility routine: band pull-apart × 20, wrist circle 30s, forearm stretch 30s. Làm mỗi sáng!", [], 12, 5, 3, now.AddDays(-13)),

            // ── User 07 – LoseFat Intermediate (4 posts) ─────────────────────
            P(29, 7, PostType.Standard, "Tuần 3 cut: -1.2kg, giữ được sức mạnh, không mệt quá. Deficit 300-400kcal/ngày hoạt động tốt! 😍", [ImgProgress], 8, 4, 1, now.AddDays(-2)),
            P(30, 7, PostType.Standard, "Smoothie đêm: sữa chua Hy Lạp + chuối + mật ong + granola → protein cao, ít calo, ngủ ngon! 🍌", [ImgFood1], 10, 5, 2, now.AddDays(-6)),
            P(31, 7, PostType.StreakShare, "18 ngày log đủ macro! Nhìn lại 3 tuần thấy tiến bộ rõ 😍 Ai đang cut cùng không?", [], 9, 4, 2, now.AddDays(-10)),
            P(32, 7, PostType.Standard, "HIIT 25p tại nhà không cần gym: Jack 30s / Burpee 30s / Climber 30s × 4 rounds. Thử đi!", [], 7, 3, 1, now.AddDays(-14)),

            // ── User 10 – Recomp Female (4 posts) ────────────────────────────
            P(33, 10, PostType.Standard, "Meal prep tuần: 5 hộp cơm gạo lứt + ức gà + rau xanh. Chuẩn bị sẵn = không ăn lung tung 🥙", [ImgFood2], 10, 5, 2, now.AddDays(-1)),
            P(34, 10, PostType.Standard, "Thành thật: tuần này vượt 200kcal 3 ngày. Không sao — nhận ra, điều chỉnh, tiếp tục 💪", [], 9, 4, 2, now.AddDays(-5)),
            P(35, 10, PostType.AchievementShare, "10 tuần recomp: -2% bodyfat và lên được 10 pull-up liên tục! Kết quả bắt đầu hiện ra 💪", [ImgProgress], 12, 6, 3, now.AddDays(-9)),
            P(36, 10, PostType.Standard, "Hip hinge là foundation của mọi bài tập lưng/mông. Học RDL đúng trước khi deadlift nặng.", [], 11, 5, 2, now.AddDays(-13)),

            // ── User 12 – BuildMuscle Female (3 posts) ───────────────────────
            P(37, 12, PostType.Standard, "Glute day: Hip thrust 70kg × 12 / Bulgarian split 10 / Abduction 15. Đau hay là tiến bộ? 😂🍑", [ImgGym3], 9, 4, 1, now.AddDays(-2)),
            P(38, 12, PostType.AchievementShare, "21 ngày streak đầu tiên! Từ 2 buổi/tuần lên 5 buổi/tuần trong 5 tuần 🔥", [ImgProgress], 10, 5, 2, now.AddDays(-7)),
            P(39, 12, PostType.Standard, "Carb cycle: ngày tập 250g carb, ngày nghỉ 150g. Đang thử xem hiệu quả như thế nào!", [], 8, 4, 1, now.AddDays(-12)),

            // ── User 02 – Muscle Gain (3 posts) ──────────────────────────────
            P(40, 2, PostType.Standard, "Back day 1 năm tập: Deadlift 120kg / Pull-up 10 rep / Row 70kg. Progress từng tuần! 💪", [ImgGym1], 7, 3, 1, now.AddDays(-3)),
            P(41, 2, PostType.Standard, "Cơm gạo lứt + ức gà + bông cải = combo không thể thiếu mỗi ngày 😄 Đơn giản, rẻ, hiệu quả.", [ImgFood3], 6, 3, 0, now.AddDays(-8)),
            P(42, 2, PostType.StreakShare, "14 ngày streak! Momentum đang cuộn 💪 Ai cùng tập không?", [], 5, 2, 0, now.AddDays(-13)),

            // ── User 06 – Runner (3 posts) ────────────────────────────────────
            P(43, 6, PostType.Standard, "6:30AM chạy 12km trail Thủ Đức. Mưa xong trời đẹp — best run tháng này! 🌅", [ImgRun2], 8, 4, 2, now.AddDays(-1)),
            P(44, 6, PostType.Standard, "Bún bò sau chạy 15km: ngon nhất thế giới 😂 Carb replenishment quan trọng lắm!", [ImgFood2], 7, 3, 1, now.AddDays(-6)),
            P(45, 6, PostType.Standard, "Zone 2 cardio 45p × 3 buổi/tuần cải thiện VO2max đáng kể sau 8 tuần. Không cần HIIT mỗi ngày.", [], 7, 3, 2, now.AddDays(-11)),

            // ── User 17 – Recomp Intermediate (2 posts) ──────────────────────
            P(46, 17, PostType.Standard, "App SYNC giúp mình thấy pattern ăn uống theo thời gian — không phải chỉ log calories. Insights rất hay!", [], 6, 3, 1, now.AddDays(-4)),
            P(47, 17, PostType.Standard, "Diet break 2 tuần sau 8 tuần deficit: leptin levels và mood cải thiện thấy rõ. Cần thiết hơn mình nghĩ!", [], 5, 2, 0, now.AddDays(-10)),

            // ── User 14 – Endurance Female (2 posts) ─────────────────────────
            P(48, 14, PostType.Standard, "Yoga 20p sáng + chạy 30p chiều: combo hoàn hảo cho mình. Không bao giờ bỏ 2 thứ này!", [ImgRun1], 7, 4, 2, now.AddDays(-2)),
            P(49, 14, PostType.Standard, "Granola + sữa hạt + chuối — bữa sáng 350kcal nhanh gọn, đủ năng lượng chạy 10km. Thử đi!", [ImgFood1], 6, 3, 1, now.AddDays(-7)),

            // ── User 09 – Maintain (2 posts) ─────────────────────────────────
            P(50, 9, PostType.Standard, "Cơm gà + canh rau = bữa trưa văn phòng hoàn hảo. Ăn đơn giản, nhất quán, không phải lo nghĩ gì.", [ImgFood3], 5, 2, 0, now.AddDays(-3)),
            P(51, 9, PostType.Standard, "Rest week: không tập nặng, đi bộ 30p/ngày, ngủ 8 tiếng. Cơ thể cần phục hồi thật sự.", [], 4, 2, 0, now.AddDays(-9)),

            // ── Beginner users (1 post each) ──────────────────────────────────
            P(52, 3, PostType.Standard, "Tuần đầu tập với SYNC! Mệt lắm nhưng vui 😅 Cố gắng đi bộ 20 phút mỗi ngày.", [], 5, 3, 0, now.AddDays(-4)),
        ];
    }

    private static Post P(int n, int authorNn, PostType type, string content, string[] media,
        int likes, int comments, int shares, DateTimeOffset createdAt, Guid? referenceId = null, bool isPublic = true) =>
        new()
        {
            Id = PostId(n),
            AuthorId = SyncSeedUsers.Id(authorNn),
            AuthorSnapshot = Author(authorNn),
            PostType = type,
            Content = content,
            ContentNormalized = string.Empty,
            MediaUrls = [.. media],
            ReferenceId = referenceId,
            IsPublic = isPublic,
            ShareCode = $"SYNCP{n:D3}",
            Metrics = new PostMetrics { LikeCount = likes, CommentCount = comments, ShareCount = shares },
            CreatedAt = createdAt,
            UpdatedAt = createdAt,
        };

    // ─── 12 Stories (8 active + 4 expired) ────────────────────────────────────
    public static IReadOnlyList<Story> GetSeedStories(DateTimeOffset utcNow) =>
    [
        // Active
        Story(1,  8,  StoryMediaType.Image,  ImgGym2,  "Squat PR day — 160kg cảm giác nhẹ như bông!",     utcNow.AddHours(-4),  active: true),
        Story(2,  21, StoryMediaType.Video,  string.Empty, "Tip khởi động 5 phút cùng mình 🔥",            utcNow.AddHours(-5),  active: true, privacy: PrivacyType.Followers),
        Story(3,  20, StoryMediaType.Image,  ImgFood1, "Meal prep bowl cá hồi chuẩn macro 🥗",             utcNow.AddHours(-3),  active: true),
        Story(4,  19, StoryMediaType.Image,  ImgRun1,  "5AM morning run — thành phố vẫn ngủ, mình chạy!", utcNow.AddHours(-6),  active: true, privacy: PrivacyType.Followers),
        Story(5,  4,  StoryMediaType.TextOnly, string.Empty, "Recomp week 16 — progress không dừng được 💪", utcNow.AddHours(-2), active: true),
        Story(6,  7,  StoryMediaType.Image,  ImgFood3, "Smoothie bữa tối healthy 🍌",                       utcNow.AddHours(-7),  active: true),
        Story(7,  15, StoryMediaType.Image,  ImgGym3,  "Leg day done ✅ Đau nhưng xứng đáng!",             utcNow.AddHours(-1),  active: true),
        Story(8,  12, StoryMediaType.Image,  ImgProgress, "21-day streak! Bắt đầu thấy kết quả rồi 😍",   utcNow.AddHours(-8),  active: true),

        // Expired
        Story(9,  8,  StoryMediaType.Video,  string.Empty, "Deadlift 180kg form video 🔥",                  utcNow.AddHours(-29), active: false, 100, 25),
        Story(10, 19, StoryMediaType.Image,  ImgRun2,  "Finish line VM Half Marathon 🎯",                   utcNow.AddHours(-28), active: false, 82, 20),
        Story(11, 21, StoryMediaType.Image,  ImgGym1,  "SYNC community growing 🌱",                         utcNow.AddHours(-30), active: false, 67, 18),
        Story(12, 20, StoryMediaType.TextOnly, string.Empty, "Hydration matters — 500ml nước lúc thức dậy!", utcNow.AddHours(-27), active: false, 44,  8),
    ];

    private static Story Story(int n, int authorNn, StoryMediaType mt, string mediaUrl, string caption,
        DateTimeOffset createdAt, bool active, int views = 0, int likes = 0, PrivacyType privacy = PrivacyType.Public)
    {
        var expiresAt = active ? createdAt.AddHours(24) : createdAt.AddHours(24);
        return new Story
        {
            Id = StoryId(n),
            AuthorId = SyncSeedUsers.Id(authorNn),
            AuthorSnapshot = Author(authorNn),
            MediaUrl = mediaUrl,
            MediaType = mt,
            Caption = caption,
            ExpiresAt = expiresAt,
            ViewCount = active ? (n * 7 % 40 + 10) : views,
            LikeCount = active ? (n * 3 % 15 + 3) : likes,
            IsActive = active,
            Privacy = privacy,
            CreatedAt = createdAt,
        };
    }

    // ─── Follow graph (~123 edges) ────────────────────────────────────────────
    public static IReadOnlyList<UserFollow> GetSeedUserFollows(DateTimeOffset utcNow)
    {
        var edges = new List<(int From, int To, FollowStatus Status)>
        {
            // ── All users follow hub User21 (18 edges) ─────────────────────
            (2,21,FollowStatus.Accepted),(3,21,FollowStatus.Accepted),(4,21,FollowStatus.Accepted),
            (5,21,FollowStatus.Accepted),(6,21,FollowStatus.Accepted),(7,21,FollowStatus.Accepted),
            (8,21,FollowStatus.Accepted),(9,21,FollowStatus.Accepted),(10,21,FollowStatus.Accepted),
            (11,21,FollowStatus.Accepted),(12,21,FollowStatus.Accepted),(13,21,FollowStatus.Accepted),
            (14,21,FollowStatus.Accepted),(15,21,FollowStatus.Accepted),(16,21,FollowStatus.Accepted),
            (17,21,FollowStatus.Accepted),(18,21,FollowStatus.Accepted),(19,21,FollowStatus.Accepted),

            // ── Most users follow hub User20 (16 edges) ─────────────────────
            (2,20,FollowStatus.Accepted),(3,20,FollowStatus.Accepted),(4,20,FollowStatus.Accepted),
            (5,20,FollowStatus.Accepted),(6,20,FollowStatus.Accepted),(7,20,FollowStatus.Accepted),
            (8,20,FollowStatus.Accepted),(9,20,FollowStatus.Accepted),(10,20,FollowStatus.Accepted),
            (11,20,FollowStatus.Accepted),(12,20,FollowStatus.Accepted),(14,20,FollowStatus.Accepted),
            (15,20,FollowStatus.Accepted),(17,20,FollowStatus.Accepted),(18,20,FollowStatus.Accepted),
            (19,20,FollowStatus.Accepted),

            // ── User08 followers (11 edges) ──────────────────────────────────
            (2,8,FollowStatus.Accepted),(4,8,FollowStatus.Accepted),(6,8,FollowStatus.Accepted),
            (7,8,FollowStatus.Accepted),(10,8,FollowStatus.Accepted),(12,8,FollowStatus.Accepted),
            (14,8,FollowStatus.Accepted),(15,8,FollowStatus.Accepted),(17,8,FollowStatus.Accepted),
            (19,8,FollowStatus.Accepted),(21,8,FollowStatus.Accepted),

            // ── User19 followers (7 edges) ───────────────────────────────────
            (6,19,FollowStatus.Accepted),(7,19,FollowStatus.Accepted),(8,19,FollowStatus.Accepted),
            (14,19,FollowStatus.Accepted),(15,19,FollowStatus.Accepted),(20,19,FollowStatus.Accepted),
            (21,19,FollowStatus.Accepted),

            // ── User04 followers (8 edges) ───────────────────────────────────
            (2,4,FollowStatus.Accepted),(8,4,FollowStatus.Accepted),(10,4,FollowStatus.Accepted),
            (12,4,FollowStatus.Accepted),(15,4,FollowStatus.Accepted),(17,4,FollowStatus.Accepted),
            (20,4,FollowStatus.Accepted),(21,4,FollowStatus.Accepted),

            // ── User15 followers (6 edges) ───────────────────────────────────
            (2,15,FollowStatus.Accepted),(4,15,FollowStatus.Accepted),(8,15,FollowStatus.Accepted),
            (12,15,FollowStatus.Accepted),(17,15,FollowStatus.Accepted),(19,15,FollowStatus.Accepted),

            // ── Hub follow-backs ─────────────────────────────────────────────
            (21,8,FollowStatus.Accepted),(21,19,FollowStatus.Accepted),(21,4,FollowStatus.Accepted),
            (21,15,FollowStatus.Accepted),(21,20,FollowStatus.Accepted),(21,2,FollowStatus.Accepted),
            (20,8,FollowStatus.Accepted),(20,19,FollowStatus.Accepted),(20,4,FollowStatus.Accepted),
            (20,15,FollowStatus.Accepted),(20,2,FollowStatus.Accepted),
            (8,4,FollowStatus.Accepted),(8,15,FollowStatus.Accepted),(8,2,FollowStatus.Accepted),
            (19,4,FollowStatus.Accepted),(19,15,FollowStatus.Accepted),(19,20,FollowStatus.Accepted),
            (4,8,FollowStatus.Accepted),(4,2,FollowStatus.Accepted),(4,19,FollowStatus.Accepted),
            (15,8,FollowStatus.Accepted),(15,4,FollowStatus.Accepted),(15,2,FollowStatus.Accepted),

            // ── Peer group follows ───────────────────────────────────────────
            // LoseFat group
            (3,7,FollowStatus.Accepted),(7,3,FollowStatus.Accepted),
            (11,7,FollowStatus.Accepted),(16,7,FollowStatus.Accepted),
            (3,11,FollowStatus.Accepted),(3,16,FollowStatus.Accepted),
            // Muscle group
            (2,12,FollowStatus.Accepted),(12,2,FollowStatus.Accepted),
            (12,15,FollowStatus.Accepted),
            // Endurance group
            (6,14,FollowStatus.Accepted),(14,6,FollowStatus.Accepted),
            (6,19,FollowStatus.Accepted),(14,19,FollowStatus.Accepted),
            // Recomp group
            (10,17,FollowStatus.Accepted),(17,10,FollowStatus.Accepted),
            (9,10,FollowStatus.Accepted),(9,17,FollowStatus.Accepted),
            // Cross follows
            (7,12,FollowStatus.Accepted),(12,7,FollowStatus.Accepted),
            (7,10,FollowStatus.Accepted),(6,9,FollowStatus.Accepted),
            (9,6,FollowStatus.Accepted),(17,2,FollowStatus.Accepted),
            (10,12,FollowStatus.Accepted),(13,14,FollowStatus.Accepted),
            (18,6,FollowStatus.Accepted),(16,3,FollowStatus.Accepted),
            (19,6,FollowStatus.Accepted),(2,6,FollowStatus.Accepted),

            // ── Pending samples ──────────────────────────────────────────────
            (11,15,FollowStatus.Pending),(5,8,FollowStatus.Pending),

            // ── Blocked sample ───────────────────────────────────────────────
            (11,18,FollowStatus.Blocked),
        };

        // Dedupe (From,To) — hub lists + follow-backs can overlap.
        var unique = edges
            .GroupBy(e => (e.From, e.To))
            .Select(g => g.First())
            .ToList();

        return unique.Select((e, idx) => new UserFollow
        {
            Id = FollowId(idx + 1),
            FollowerId = SyncSeedUsers.Id(e.From),
            FolloweeId = SyncSeedUsers.Id(e.To),
            FollowedAt = utcNow.AddDays(-((idx % 50) + 3)),
            Status = e.Status,
            CreatedAt = utcNow.AddDays(-((idx % 50) + 3)),
        }).ToList();
    }

    // ─── Comments (matching post CommentCount) ────────────────────────────────
    public static IReadOnlyList<Comment> GetSeedComments(DateTimeOffset utcNow)
    {
        var posts = GetSeedPosts(utcNow);
        var comments = new List<Comment>();
        var usersPool = SyncSeedUsers.WithProfiles.Select(u => u.Id).ToArray(); // 02-21
        var ci = 1;

        for (var pi = 0; pi < posts.Count; pi++)
        {
            var post = posts[pi];
            var commenters = usersPool.Where(u => u != post.AuthorId).ToArray();

            for (var k = 0; k < post.Metrics.CommentCount; k++)
            {
                var commenterIdx = (pi * 3 + k * 7) % commenters.Length;
                var commenterId = commenters[commenterIdx];
                var user = SyncSeedUsers.All.First(u => u.Id == commenterId);
                var templateIdx = (pi + k * 2) % CommentTemplates.Length;

                comments.Add(new Comment
                {
                    Id = CommentId(pi, ci++),
                    PostId = post.Id,
                    UserId = commenterId,
                    Content = CommentTemplates[templateIdx],
                    AuthorSnapshot = Author(user.Nn),
                    CreatedAt = post.CreatedAt.AddMinutes(k * 20 + 15),
                    UpdatedAt = post.CreatedAt.AddMinutes(k * 20 + 15),
                });
            }
        }

        return comments;
    }

    // ─── Interactions (matching LikeCount + ShareCount) ───────────────────────
    public static IReadOnlyList<Interaction> GetSeedInteractions(DateTimeOffset utcNow)
    {
        var posts = GetSeedPosts(utcNow);
        var interactions = new List<Interaction>();
        var usersPool = SyncSeedUsers.WithProfiles.Select(u => u.Id).ToArray(); // 02-21
        var ii = 1;

        for (var pi = 0; pi < posts.Count; pi++)
        {
            var post = posts[pi];
            var likerPool = usersPool.Where(u => u != post.AuthorId).ToArray();

            // Generate likes
            for (var k = 0; k < post.Metrics.LikeCount; k++)
            {
                var likerId = likerPool[(pi * 5 + k * 3) % likerPool.Length];
                interactions.Add(new Interaction
                {
                    Id = InteractionId(pi, ii++),
                    PostId = post.Id,
                    UserId = likerId,
                    InteractionType = InteractionType.Like,
                    CreatedAt = post.CreatedAt.AddMinutes(k * 10 + 5),
                    UpdatedAt = post.CreatedAt.AddMinutes(k * 10 + 5),
                });
            }

            // Generate shares
            for (var k = 0; k < post.Metrics.ShareCount; k++)
            {
                var sharerId = likerPool[(pi * 5 + post.Metrics.LikeCount + k * 3) % likerPool.Length];
                interactions.Add(new Interaction
                {
                    Id = InteractionId(pi, ii++),
                    PostId = post.Id,
                    UserId = sharerId,
                    InteractionType = InteractionType.Share,
                    CreatedAt = post.CreatedAt.AddMinutes(post.Metrics.LikeCount * 10 + k * 10 + 5),
                    UpdatedAt = post.CreatedAt.AddMinutes(post.Metrics.LikeCount * 10 + k * 10 + 5),
                });
            }
        }

        return interactions;
    }

    // ─── Community Challenges (preserved, updated user IDs) ───────────────────
    public static IReadOnlyList<CommunityChallenge> GetSeedCommunityChallenges(DateTimeOffset utcNow) =>
    [
        BuildChallenge(ChallengeActiveId, SyncSeedUsers.User21,
            "Thử thách 100km Tháng 6", "Cùng chạy/đạp tổng 100km trong tháng 6. Hoàn thành nhận 500 điểm SYNC!",
            utcNow.AddDays(-20), utcNow.AddDays(-10), utcNow.AddDays(-5), utcNow.AddDays(25),
            ChallengeGoalType.TotalDistance, 100, 500, ["Badge 100K", "Áo thun SYNC"],
            ChallengeBackgroundUrls[ChallengeActiveId],
            "Công viên Tao Đàn, Quận 1, TP.HCM",
            new GeoJsonPoint<GeoJson2DGeographicCoordinates>(new GeoJson2DGeographicCoordinates(106.660172, 10.762622)),
            5, utcNow),
        BuildChallenge(ChallengeUpcomingId, SyncSeedUsers.User20,
            "Thử thách Đốt mỡ 5000 Kcal", "Đốt 5000 kcal trong 30 ngày qua cardio và strength training.",
            utcNow.AddDays(-3), utcNow.AddDays(10), utcNow.AddDays(14), utcNow.AddDays(44),
            ChallengeGoalType.TotalCaloriesBurned, 5000, 400, ["Shaker SYNC"],
            ChallengeBackgroundUrls[ChallengeUpcomingId],
            "Landmark 81, Bình Thạnh, TP.HCM",
            new GeoJsonPoint<GeoJson2DGeographicCoordinates>(new GeoJson2DGeographicCoordinates(106.7220, 10.7951)),
            0, utcNow),
        BuildChallenge(ChallengeUpcomingWaitingId, SyncSeedUsers.User08,
            "Sprint 21 Ngày Core", "21 ngày tập core — đăng ký đã đóng, chờ bắt đầu.",
            utcNow.AddDays(-14), utcNow.AddDays(-2), utcNow.AddDays(7), utcNow.AddDays(28),
            ChallengeGoalType.TotalWorkouts, 21, 350, ["Badge Core"],
            ChallengeBackgroundUrls[ChallengeUpcomingWaitingId],
            "Sân vận động Thống Nhất, TP.HCM",
            new GeoJsonPoint<GeoJson2DGeographicCoordinates>(new GeoJson2DGeographicCoordinates(106.6688, 10.8003)),
            12, utcNow),
        BuildChallenge(ChallengeCompletedId, SyncSeedUsers.User21,
            "Chuỗi 14 ngày Workout", "Tập liên tục 14 ngày — không bỏ lỡ một buổi!",
            utcNow.AddMonths(-2), utcNow.AddDays(-45), utcNow.AddDays(-40), utcNow.AddDays(-14),
            ChallengeGoalType.TotalWorkouts, 14, 300, ["Voucher 200k"],
            ChallengeBackgroundUrls[ChallengeCompletedId],
            "SYNC Fitness Hub, Quận 7, TP.HCM",
            new GeoJsonPoint<GeoJson2DGeographicCoordinates>(new GeoJson2DGeographicCoordinates(106.7204, 10.7295)),
            4, utcNow),
    ];

    private static CommunityChallenge BuildChallenge(Guid id, Guid creatorId, string title, string desc,
        DateTimeOffset createdAt, DateTimeOffset regDeadline, DateTimeOffset startDate, DateTimeOffset endDate,
        ChallengeGoalType goalType, decimal targetValue, decimal pointRewards, string[] gifts,
        string? backgroundUrl, string address, GeoJsonPoint<GeoJson2DGeographicCoordinates> location,
        int participantCount, DateTimeOffset utcNow)
    {
        var c = new CommunityChallenge
        {
            Id = id, CreatorId = creatorId, Title = title, Description = desc,
            RegistrationDeadline = regDeadline, StartDate = startDate, EndDate = endDate,
            GoalType = goalType, TargetValue = targetValue, PointRewards = pointRewards,
            Gifts = gifts, BackgroundUrl = backgroundUrl, Address = address, Location = location,
            ParticipantCount = participantCount, CreatedAt = createdAt,
        };
        c.Status = ChallengeStatusResolver.Resolve(c, utcNow);
        return c;
    }

    // ─── Challenge Participants ────────────────────────────────────────────────
    public static IReadOnlyList<ChallengeParticipant> GetSeedChallengeParticipants(DateTimeOffset utcNow) =>
    [
        CP("c7000001-0000-0000-0000-000000000001", ChallengeActiveId, SyncSeedUsers.User08, ParticipantStatus.InProgress, utcNow.AddDays(-4)),
        CP("c7000002-0000-0000-0000-000000000002", ChallengeActiveId, SyncSeedUsers.User19, ParticipantStatus.InProgress, utcNow.AddDays(-3)),
        CP("c7000003-0000-0000-0000-000000000003", ChallengeActiveId, SyncSeedUsers.User06, ParticipantStatus.Joined,     utcNow.AddDays(-1)),
        CP("c7000004-0000-0000-0000-000000000004", ChallengeActiveId, SyncSeedUsers.User04, ParticipantStatus.InProgress, utcNow.AddDays(-4)),
        CP("c7000005-0000-0000-0000-000000000005", ChallengeActiveId, SyncSeedUsers.User14, ParticipantStatus.Joined,     utcNow.AddDays(-2)),
        CP("c7000006-0000-0000-0000-000000000006", ChallengeCompletedId, SyncSeedUsers.User08, ParticipantStatus.Completed, utcNow.AddMonths(-1), utcNow.AddDays(-15)),
        CP("c7000007-0000-0000-0000-000000000007", ChallengeCompletedId, SyncSeedUsers.User04, ParticipantStatus.Completed, utcNow.AddMonths(-1).AddDays(1), utcNow.AddDays(-14)),
        CP("c7000008-0000-0000-0000-000000000008", ChallengeCompletedId, SyncSeedUsers.User03, ParticipantStatus.Dropped,   utcNow.AddMonths(-1).AddDays(2)),
    ];

    private static ChallengeParticipant CP(string id, Guid challengeId, Guid userId, ParticipantStatus status,
        DateTimeOffset joinedAt, DateTimeOffset? completedAt = null) =>
        new() { Id = Guid.Parse(id), ChallengeId = challengeId, UserId = userId, Status = status,
            JoinedAt = joinedAt, CompletedAt = completedAt, IsActive = status != ParticipantStatus.Dropped,
            CreatedAt = joinedAt };

    // ─── Blogs ────────────────────────────────────────────────────────────────
    public static IReadOnlyList<Blog> GetSeedBlogs(DateTimeOffset utcNow) =>
    [
        new Blog
        {
            Id = Guid.Parse("c5000001-0000-0000-0000-000000000001"),
            AuthorId = SyncSeedUsers.User21,
            AuthorSnapshot = Author(21),
            Title = "Hướng dẫn hít thở đúng cách khi tập tạ",
            Slug = "hit-tho-dung-cach",
            CoverImageUrl = ImgGym1,
            Content = "<h2>Nguyên tắc cơ bản</h2><p>Hạ tạ: hít vào — đẩy tạ: thở ra. Giữ core căng suốt rep để bảo vệ cột sống và tăng lực.</p><h3>Lỗi thường gặp</h3><ul><li>Nín thở khi squat nặng</li><li>Thở quá nhanh khi deadlift</li><li>Vai gù khi bench press</li></ul><p>Hãy luyện thói quen thở có kiểm soát từ set khởi động — hiệu suất sẽ ổn định hơn rõ rệt.</p>",
            Tags = ["strength", "breathing", "beginner"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddDays(-10),
            LikeCount = 45, ShareCount = 12, CommentCount = 3, CreatedAt = utcNow.AddDays(-12),
        },
        new Blog
        {
            Id = Guid.Parse("c5000002-0000-0000-0000-000000000002"),
            AuthorId = SyncSeedUsers.User20,
            AuthorSnapshot = Author(20),
            Title = "Chế độ ăn Keto có thực sự tốt cho người tập Gym?",
            Slug = "an-keto-tap-gym",
            CoverImageUrl = ImgFood2,
            Content = "<p>Keto giảm carb dưới 50g/ngày, đẩy cơ thể sang trạng thái ketosis. Ưu điểm: kiểm soát cân nhanh, cảm giác no lâu. Nhược: giảm hiệu suất tập nặng giai đoạn đầu vì glycogen thấp.</p><h3>Ai nên cân nhắc?</h3><ul><li>Mục tiêu giảm mỡ ưu tiên</li><li>Không tập volume cao / powerlifting</li></ul><p>Nếu bạn đang build cơ hoặc theo lộ trình strength, hãy ưu tiên carb quanh buổi tập thay vì keto cứng.</p>",
            Tags = ["nutrition", "keto", "gym"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddDays(-5),
            LikeCount = 38, ShareCount = 9, CommentCount = 2, CreatedAt = utcNow.AddDays(-7),
        },
        new Blog
        {
            Id = Guid.Parse("c5000003-0000-0000-0000-000000000003"),
            AuthorId = SyncSeedUsers.User08,
            AuthorSnapshot = Author(8),
            Title = "Giáo án 4 ngày/tuần cho người tập intermediate",
            Slug = "giao-an-4-ngay-intermediate",
            CoverImageUrl = ImgGym3,
            Content = "<h2>Tuần 1–4</h2><ul><li>Thứ 2: Upper body</li><li>Thứ 4: Lower body</li><li>Thứ 6: Full body</li><li>Thứ 7: Cardio 30 phút</li></ul>",
            Tags = ["workout-plan", "intermediate", "4-day-split"],
            Status = BlogStatus.Draft, LikeCount = 0, ShareCount = 0, CommentCount = 0, CreatedAt = utcNow.AddDays(-3),
        },
        new Blog
        {
            Id = Guid.Parse("c5000004-0000-0000-0000-000000000004"),
            AuthorId = SyncSeedUsers.User11,
            AuthorSnapshot = Author(11),
            Title = "Ngủ đủ 7–8 giờ: lợi thế bí mật của người tập đều",
            Slug = "ngu-du-tang-phuc-hoi",
            CoverImageUrl = ImgProgress,
            Content = "<h2>Vì sao giấc ngủ quan trọng?</h2><p>Hormone tăng trưởng, phục hồi cơ và kiểm soát cortisol đều phụ thuộc vào chất lượng giấc ngủ. Thiếu ngủ làm bạn thèm đồ ngọt hơn và giảm sức chịu đựng khi tập.</p><h3>Thói quen đơn giản</h3><ul><li>Cố định giờ ngủ / thức dậy</li><li>Tắt màn hình sáng 45 phút trước ngủ</li><li>Phòng tối, mát, yên</li></ul><p>Coi giấc ngủ là một phần của lộ trình — không phải phần 'nếu còn thời gian'.</p>",
            Tags = ["recovery", "sleep", "lifestyle"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddDays(-3),
            LikeCount = 52, ShareCount = 14, CommentCount = 2, CreatedAt = utcNow.AddDays(-4),
        },
        new Blog
        {
            Id = Guid.Parse("c5000005-0000-0000-0000-000000000005"),
            AuthorId = SyncSeedUsers.User05,
            AuthorSnapshot = Author(5),
            Title = "Protein sau tập: bao nhiêu là đủ?",
            Slug = "protein-sau-tap",
            CoverImageUrl = ImgFood1,
            Content = "<p>Sau buổi tập, cơ thể cần protein để sửa chữa sợi cơ. Mục tiêu phổ biến: khoảng <strong>20–40g protein</strong> trong 1–2 giờ sau tập, kết hợp carb nếu buổi tập dài hoặc nặng.</p><h3>Gợi ý thực tế</h3><ul><li>Ức gà + cơm</li><li>Sữa chua Hy Lạp + trái cây</li><li>Smoothie whey + chuối</li></ul><p>Không cần 'anabolic window' siêu hẹp — quan trọng hơn là tổng protein trong ngày đạt mục tiêu.</p>",
            Tags = ["nutrition", "protein", "recovery"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddDays(-2),
            LikeCount = 61, ShareCount = 18, CommentCount = 1, CreatedAt = utcNow.AddDays(-3),
        },
        new Blog
        {
            Id = Guid.Parse("c5000006-0000-0000-0000-000000000006"),
            AuthorId = SyncSeedUsers.User14,
            AuthorSnapshot = Author(14),
            Title = "Chạy bộ cho người mới: từ 0 lên 5km trong 4 tuần",
            Slug = "chay-bo-5km-4-tuan",
            CoverImageUrl = ImgRun1,
            Content = "<h2>Nguyên tắc</h2><p>Xen kẽ đi bộ và chạy nhẹ, tăng dần thời gian chạy mỗi tuần. Đừng tăng quá 10% khối lượng mỗi tuần để giảm chấn thương.</p><h3>Tuần mẫu</h3><ul><li>Tuần 1: chạy 1 phút / đi 2 phút × 8</li><li>Tuần 2: chạy 2 phút / đi 2 phút × 7</li><li>Tuần 3: chạy 4 phút / đi 1 phút × 6</li><li>Tuần 4: chạy liên tục 20–25 phút</li></ul><p>Giày phù hợp và khởi động 5 phút là bắt buộc.</p>",
            Tags = ["cardio", "running", "beginner"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddDays(-1),
            LikeCount = 73, ShareCount = 21, CommentCount = 2, CreatedAt = utcNow.AddDays(-2),
        },
        new Blog
        {
            Id = Guid.Parse("c5000007-0000-0000-0000-000000000007"),
            AuthorId = SyncSeedUsers.User02,
            AuthorSnapshot = Author(2),
            Title = "Mobility 10 phút mỗi sáng: ít nhưng đều",
            Slug = "mobility-10-phut",
            CoverImageUrl = ImgGym2,
            Content = "<p>Mobility giúp khớp linh hoạt hơn, giảm cảm giác cứng khi squat và deadlift. Chỉ cần 10 phút mỗi sáng trước khi bắt đầu ngày.</p><h3>Chuỗi gợi ý</h3><ul><li>Cổ / vai: vòng tròn nhẹ</li><li>Hông: 90/90 stretch</li><li>Cổ chân: knee-over-toe rock</li><li>Cột sống ngực: open book</li></ul><p>Đều đặn quan trọng hơn cường độ — hãy gắn mobility vào thói quen đánh răng buổi sáng.</p>",
            Tags = ["mobility", "warmup", "lifestyle"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddHours(-8),
            LikeCount = 29, ShareCount = 7, CommentCount = 1, CreatedAt = utcNow.AddDays(-1),
        },
        new Blog
        {
            Id = Guid.Parse("c5000008-0000-0000-0000-000000000008"),
            AuthorId = SyncSeedUsers.User21,
            AuthorSnapshot = Author(21),
            Title = "Cách đọc nhãn dinh dưỡng khi mua Sync Foods",
            Slug = "doc-nhan-dinh-duong",
            CoverImageUrl = ImgFood3,
            Content = "<h2>Nhìn gì trước?</h2><p>Calories chỉ là một phần. Ưu tiên protein cao, đường thêm thấp, và khẩu phần thực tế bạn sẽ ăn.</p><ul><li>Protein ≥ 15g / khẩu phần nếu là bữa chính</li><li>Đường thêm càng thấp càng tốt với món snack</li><li>So sánh theo 100g thay vì theo bao bì</li></ul><p>Kết hợp với nhật ký dinh dưỡng trong app để giữ deficit hoặc surplus ổn định.</p>",
            Tags = ["nutrition", "sync-foods", "tips"],
            Status = BlogStatus.Published, PublishedAt = utcNow.AddHours(-2),
            LikeCount = 41, ShareCount = 11, CommentCount = 1, CreatedAt = utcNow.AddHours(-6),
        },
    ];

    private static Guid BlogCommentId(int blogNn, int ci) =>
        Guid.Parse($"c6{blogNn:D2}{ci:D4}-0000-4000-a000-000000000000");

    public static IReadOnlyList<BlogComment> GetSeedBlogComments(DateTimeOffset utcNow) =>
    [
        new BlogComment
        {
            Id = BlogCommentId(1, 1), BlogId = Guid.Parse("c5000001-0000-0000-0000-000000000001"),
            UserId = SyncSeedUsers.User02, AuthorSnapshot = Author(2),
            Content = "Mình áp dụng cách thở này khi squat, cảm giác vững hẳn!",
            CreatedAt = utcNow.AddDays(-9),
        },
        new BlogComment
        {
            Id = BlogCommentId(1, 2), BlogId = Guid.Parse("c5000001-0000-0000-0000-000000000001"),
            UserId = SyncSeedUsers.User05, AuthorSnapshot = Author(5),
            Content = "Phần lỗi thường gặp rất đúng — mình hay nín thở khi nặng.",
            CreatedAt = utcNow.AddDays(-8),
        },
        new BlogComment
        {
            Id = BlogCommentId(1, 3), BlogId = Guid.Parse("c5000001-0000-0000-0000-000000000001"),
            UserId = SyncSeedUsers.User11, AuthorSnapshot = Author(11),
            Content = "Cảm ơn bài viết, rõ ràng và dễ áp dụng.",
            CreatedAt = utcNow.AddDays(-7),
        },
        new BlogComment
        {
            Id = BlogCommentId(2, 1), BlogId = Guid.Parse("c5000002-0000-0000-0000-000000000002"),
            UserId = SyncSeedUsers.User03, AuthorSnapshot = Author(3),
            Content = "Mình thử keto 2 tuần rồi quay lại carb quanh buổi tập — thấy tốt hơn.",
            CreatedAt = utcNow.AddDays(-4),
        },
        new BlogComment
        {
            Id = BlogCommentId(2, 2), BlogId = Guid.Parse("c5000002-0000-0000-0000-000000000002"),
            UserId = SyncSeedUsers.User14, AuthorSnapshot = Author(14),
            Content = "Bài viết cân bằng, không cực đoan. Hay!",
            CreatedAt = utcNow.AddDays(-3),
        },
        new BlogComment
        {
            Id = BlogCommentId(4, 1), BlogId = Guid.Parse("c5000004-0000-0000-0000-000000000004"),
            UserId = SyncSeedUsers.User08, AuthorSnapshot = Author(8),
            Content = "Ngủ đúng giờ giúp mình tập sáng khỏe hơn hẳn.",
            CreatedAt = utcNow.AddDays(-2),
        },
        new BlogComment
        {
            Id = BlogCommentId(4, 2), BlogId = Guid.Parse("c5000004-0000-0000-0000-000000000004"),
            UserId = SyncSeedUsers.User20, AuthorSnapshot = Author(20),
            Content = "Tip tắt màn hình trước ngủ rất thực tế.",
            CreatedAt = utcNow.AddDays(-1),
        },
        new BlogComment
        {
            Id = BlogCommentId(5, 1), BlogId = Guid.Parse("c5000005-0000-0000-0000-000000000005"),
            UserId = SyncSeedUsers.User02, AuthorSnapshot = Author(2),
            Content = "Smoothie whey + chuối là combo mình dùng mỗi ngày.",
            CreatedAt = utcNow.AddDays(-1),
        },
        new BlogComment
        {
            Id = BlogCommentId(6, 1), BlogId = Guid.Parse("c5000006-0000-0000-0000-000000000006"),
            UserId = SyncSeedUsers.User05, AuthorSnapshot = Author(5),
            Content = "Tuần 1 quá dễ theo — cảm ơn giáo án!",
            CreatedAt = utcNow.AddHours(-20),
        },
        new BlogComment
        {
            Id = BlogCommentId(6, 2), BlogId = Guid.Parse("c5000006-0000-0000-0000-000000000006"),
            UserId = SyncSeedUsers.User11, AuthorSnapshot = Author(11),
            Content = "Nhớ khởi động và chọn giày đúng size nha mọi người.",
            CreatedAt = utcNow.AddHours(-12),
        },
        new BlogComment
        {
            Id = BlogCommentId(7, 1), BlogId = Guid.Parse("c5000007-0000-0000-0000-000000000007"),
            UserId = SyncSeedUsers.User14, AuthorSnapshot = Author(14),
            Content = "10 phút thật sự đủ nếu làm đều mỗi ngày.",
            CreatedAt = utcNow.AddHours(-4),
        },
        new BlogComment
        {
            Id = BlogCommentId(8, 1), BlogId = Guid.Parse("c5000008-0000-0000-0000-000000000008"),
            UserId = SyncSeedUsers.User03, AuthorSnapshot = Author(3),
            Content = "Mẹo so sánh theo 100g rất hữu ích khi order Sync Foods.",
            CreatedAt = utcNow.AddHours(-1),
        },
    ];

    // ─── Static SeedAsync (merged from SocialDatabaseSeeder) ─────────────────
    public static async Task SeedAsync(
        IMongoDatabase database,
        bool enabled = true,
        CancellationToken cancellationToken = default)
    {
        if (!enabled) return;

        await PatchLegacyCdnUrlsAsync(database, cancellationToken);
        await PatchChallengeBackgroundUrlsAsync(database, cancellationToken);

        var utcNow = DateTimeOffset.UtcNow;

        // Always upsert missing blogs/comments so enriching seed works on existing DBs.
        await InsertMissingAsync(database.GetCollection<Blog>("Blogs"),
            GetSeedBlogs(utcNow), cancellationToken);
        await InsertMissingAsync(database.GetCollection<BlogComment>("BlogComments"),
            GetSeedBlogComments(utcNow), cancellationToken);
        await SyncSeedBlogCommentCountsAsync(database, utcNow, cancellationToken);

        var posts = database.GetCollection<Post>("Posts");
        if (await posts.Find(x => x.Id == SeedMarkerPostId).AnyAsync(cancellationToken))
            return;

        await InsertMissingAsync(database.GetCollection<CommunityChallenge>("CommunityChallenges"),
            GetSeedCommunityChallenges(utcNow), cancellationToken);
        await InsertMissingAsync(database.GetCollection<ChallengeParticipant>("ChallengeParticipants"),
            GetSeedChallengeParticipants(utcNow), cancellationToken);
        await InsertMissingAsync(posts, GetSeedPosts(utcNow), cancellationToken);
        await InsertMissingAsync(database.GetCollection<Story>("Stories"),
            GetSeedStories(utcNow), cancellationToken);
        await InsertMissingAsync(database.GetCollection<UserFollow>("UserFollows"),
            GetSeedUserFollows(utcNow), cancellationToken);
        await InsertMissingAsync(database.GetCollection<Comment>("Comments"),
            GetSeedComments(utcNow), cancellationToken);
        await InsertMissingInteractionsAsync(database, utcNow, cancellationToken);
    }

    private static async Task SyncSeedBlogCommentCountsAsync(
        IMongoDatabase database,
        DateTimeOffset utcNow,
        CancellationToken ct)
    {
        var blogs = database.GetCollection<Blog>("Blogs");
        var commentsByBlog = GetSeedBlogComments(utcNow)
            .GroupBy(c => c.BlogId)
            .ToDictionary(g => g.Key, g => g.Count());

        foreach (var (blogId, count) in commentsByBlog)
        {
            await blogs.UpdateOneAsync(
                x => x.Id == blogId,
                Builders<Blog>.Update.Set(x => x.CommentCount, count),
                cancellationToken: ct);
        }
    }

    private static async Task InsertMissingInteractionsAsync(
        IMongoDatabase database, DateTimeOffset utcNow, CancellationToken ct)
    {
        var collection = database.GetCollection<Interaction>("Interactions");
        var seeds = GetSeedInteractions(utcNow);
        var ids = seeds.Select(x => x.Id).ToList();

        var existingIds = await collection
            .Find(Builders<Interaction>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(ct);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        if (toInsert.Count == 0) return;

        await collection.InsertManyAsync(toInsert, cancellationToken: ct);
    }

    private static async Task InsertMissingAsync<T>(
        IMongoCollection<T> collection, IReadOnlyList<T> seeds, CancellationToken ct)
        where T : BaseMongoEntity
    {
        var ids = seeds.Select(x => x.Id).ToList();
        var existingIds = await collection
            .Find(Builders<T>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(ct);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        if (toInsert.Count == 0) return;

        var now = DateTimeOffset.UtcNow;
        foreach (var e in toInsert)
        {
            if (e.CreatedAt == default) e.CreatedAt = now;
            e.UpdatedAt = now;
        }

        await collection.InsertManyAsync(toInsert, cancellationToken: ct);
    }

    private static async Task PatchLegacyCdnUrlsAsync(IMongoDatabase database, CancellationToken ct)
    {
        var posts = database.GetCollection<Post>("Posts");
        var legacyFilter = Builders<Post>.Filter.Or(
            Builders<Post>.Filter.Regex(
                x => x.AuthorSnapshot.AvatarUrl,
                new MongoDB.Bson.BsonRegularExpression(DevSeedMediaUrls.LegacyCdnHost, "i")),
            Builders<Post>.Filter.Regex(
                "MediaUrls",
                new MongoDB.Bson.BsonRegularExpression(DevSeedMediaUrls.LegacyCdnHost, "i")));

        var legacyPosts = await posts.Find(legacyFilter).ToListAsync(ct);
        foreach (var post in legacyPosts)
        {
            if (post.AuthorSnapshot is not null && !string.IsNullOrWhiteSpace(post.AuthorSnapshot.AvatarUrl))
                post.AuthorSnapshot.AvatarUrl = DevSeedMediaUrls.MigrateLegacyUrl(post.AuthorSnapshot.AvatarUrl);
            if (post.MediaUrls is { Count: > 0 })
                post.MediaUrls = post.MediaUrls.Select(DevSeedMediaUrls.MigrateLegacyUrl).ToList();
            await posts.ReplaceOneAsync(
                Builders<Post>.Filter.Eq(x => x.Id, post.Id), post, cancellationToken: ct);
        }
    }

    private static async Task PatchChallengeBackgroundUrlsAsync(IMongoDatabase database, CancellationToken ct)
    {
        var collection = database.GetCollection<CommunityChallenge>("CommunityChallenges");
        foreach (var (id, backgroundUrl) in ChallengeBackgroundUrls)
        {
            var filter = Builders<CommunityChallenge>.Filter.And(
                Builders<CommunityChallenge>.Filter.Eq(x => x.Id, id),
                Builders<CommunityChallenge>.Filter.Or(
                    Builders<CommunityChallenge>.Filter.Exists(x => x.BackgroundUrl, false),
                    Builders<CommunityChallenge>.Filter.Eq(x => x.BackgroundUrl, null),
                    Builders<CommunityChallenge>.Filter.Eq(x => x.BackgroundUrl, string.Empty)));
            await collection.UpdateOneAsync(filter,
                Builders<CommunityChallenge>.Update
                    .Set(x => x.BackgroundUrl, backgroundUrl)
                    .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow),
                cancellationToken: ct);
        }
    }
}
