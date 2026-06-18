using Social.Domain.Models;

namespace Social.Infrastructure.Persistence.Seed;

internal static class SocialSeedAuthors
{
    public static AuthorSnapshot Admin => new()
    {
        FullName = "SYNC Admin",
        AvatarUrl = "https://i.pravatar.cc/150?u=admin",
    };

    public static AuthorSnapshot ProAthlete => new()
    {
        FullName = "Khải Nguyễn",
        AvatarUrl = "https://i.pravatar.cc/150?u=khai",
    };

    public static AuthorSnapshot Beginner => new()
    {
        FullName = "Trần Thể Lực",
        AvatarUrl = "https://i.pravatar.cc/150?u=tran",
    };

    public static AuthorSnapshot Nutritionist => new()
    {
        FullName = "Lê Dinh Dưỡng",
        AvatarUrl = "https://i.pravatar.cc/150?u=le",
    };

    public static AuthorSnapshot ActiveMember => new()
    {
        FullName = "Phạm Cardio",
        AvatarUrl = "https://i.pravatar.cc/150?u=pham",
    };
}
