namespace Libs.Shared.Seed;

/// <summary>
/// Canonical 21 demo users from SYNC-Seed-Dataset-Spec (§1).
/// Cross-service seeds must reference these GUIDs only.
/// </summary>
public static class SyncSeedUsers
{
    public const string DefaultDevPassword = "Sync@12345";

    public static Guid Id(int nn) =>
        Guid.Parse($"a1b20000-0000-4000-a000-0000000000{nn:D2}");

    public static readonly Guid User01 = Id(1);
    public static readonly Guid User02 = Id(2);
    public static readonly Guid User03 = Id(3);
    public static readonly Guid User04 = Id(4);
    public static readonly Guid User05 = Id(5);
    public static readonly Guid User06 = Id(6);
    public static readonly Guid User07 = Id(7);
    public static readonly Guid User08 = Id(8);
    public static readonly Guid User09 = Id(9);
    public static readonly Guid User10 = Id(10);
    public static readonly Guid User11 = Id(11);
    public static readonly Guid User12 = Id(12);
    public static readonly Guid User13 = Id(13);
    public static readonly Guid User14 = Id(14);
    public static readonly Guid User15 = Id(15);
    public static readonly Guid User16 = Id(16);
    public static readonly Guid User17 = Id(17);
    public static readonly Guid User18 = Id(18);
    public static readonly Guid User19 = Id(19);
    public static readonly Guid User20 = Id(20);
    public static readonly Guid User21 = Id(21);

    /// <summary>Empty onboarding account — User row only.</summary>
    public static readonly Guid EmptyUserId = User01;

    /// <summary>Partner / KOL (Mai Thị Kim Chi).</summary>
    public static readonly Guid PartnerUserId = User20;

    /// <summary>SystemAdmin / community coach (Trương Công Định).</summary>
    public static readonly Guid AdminUserId = User21;

    public static IReadOnlyList<SyncSeedUserDef> All { get; } =
    [
        new(1, "Nguyễn Minh Khôi", "khoi.mtest@gmail.com", "User", "Free", Empty: true),
        new(2, "Trần Quốc Bảo", "quocbao.tran@gmail.com", "User", "Premium"),
        new(3, "Lê Thị Thu Hà", "thuha.le88@gmail.com", "User", "Free"),
        new(4, "Phạm Anh Tuấn", "anhtuan.pham@gmail.com", "User", "Ultra"),
        new(5, "Vũ Ngọc Lan", "ngoclan.vu@gmail.com", "User", "Free"),
        new(6, "Đặng Hoàng Long", "hoanglong.dang@gmail.com", "User", "Premium"),
        new(7, "Bùi Thị Mai", "thimai.bui@gmail.com", "User", "Premium"),
        new(8, "Hoàng Văn Nam", "vannam.hoang@gmail.com", "User", "Ultra"),
        new(9, "Ngô Thanh Tùng", "thanhtung.ngo@gmail.com", "User", "Premium"),
        new(10, "Đỗ Thùy Linh", "thuylinh.do@gmail.com", "User", "Premium"),
        new(11, "Nguyễn Hải Đăng", "haidang.nguyen@gmail.com", "User", "Free"),
        new(12, "Trịnh Thị Ngân", "thingan.trinh@gmail.com", "User", "Premium"),
        new(13, "Lý Gia Huy", "giahuy.ly@gmail.com", "User", "Free"),
        new(14, "Phan Khánh Vy", "khanhvy.phan@gmail.com", "User", "Premium"),
        new(15, "Võ Minh Quân", "minhquan.vo@gmail.com", "User", "Ultra"),
        new(16, "Đinh Thị Hồng", "thihong.dinh@gmail.com", "User", "Free"),
        new(17, "Cao Đức Anh", "ducanh.cao@gmail.com", "User", "Premium"),
        new(18, "Dương Bảo Ngọc", "baongoc.duong@gmail.com", "User", "Free"),
        new(19, "Hồ Sĩ Phú", "siphu.ho@gmail.com", "User", "Premium"),
        new(20, "Mai Thị Kim Chi", "kimchi.mai@gmail.com", "Partner", "Ultra"),
        new(21, "Trương Công Định", "congdinh.truong@gmail.com", "SystemAdmin", "Ultra"),
    ];

    public static IEnumerable<SyncSeedUserDef> WithProfiles => All.Where(u => !u.Empty);

    public static string AvatarUrl(string email) =>
        $"randomavatar:{email.Trim().ToLowerInvariant()}";

    public static Guid ChildId(string prefix, int nn) =>
        Guid.Parse($"{prefix}-0000-4000-a000-0000000000{nn:D2}");
}

public sealed record SyncSeedUserDef(
    int Nn,
    string FullName,
    string Email,
    string Role,
    string Tier,
    bool Empty = false)
{
    public Guid Id => SyncSeedUsers.Id(Nn);
}
