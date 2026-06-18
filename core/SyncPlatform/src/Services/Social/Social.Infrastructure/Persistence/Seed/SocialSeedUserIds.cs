namespace Social.Infrastructure.Persistence.Seed;

/// <summary>Fixed IAM user IDs — must match IAM <c>Users</c> seed.</summary>
public static class SocialSeedUserIds
{
    /// <summary>SYNC Admin / Coach</summary>
    public static readonly Guid Admin = Guid.Parse("d3b07384-d9a4-4a5c-9742-832103328ce1");

    /// <summary>Khải Nguyễn — Pro Athlete</summary>
    public static readonly Guid ProAthlete = Guid.Parse("8f3a5595-6b58-450e-8fb8-228bc7f59041");

    /// <summary>Trần Thể Lực — Beginner</summary>
    public static readonly Guid Beginner = Guid.Parse("114ab811-1a3f-4e0d-b4f0-b8d9eb93cd84");

    /// <summary>Lê Dinh Dưỡng — Nutritionist</summary>
    public static readonly Guid Nutritionist = Guid.Parse("c55ef9c8-251c-4cf2-8cb2-e3e8f85cb159");

    /// <summary>Phạm Cardio — Active Member</summary>
    public static readonly Guid ActiveMember = Guid.Parse("9081db2b-f3b3-4610-85f4-3d601d51a6fb");

    /// <summary>Default demo login — maps to Beginner (Trần Thể Lực).</summary>
    public static readonly Guid Demo = Beginner;
}
