using Social.Domain.Models;

namespace Social.Infrastructure.Persistence.Seed;

internal static class SocialSeedAuthors
{
    public static AuthorSnapshot Demo => new()
    {
        FullName = "Nguyễn Demo SYNC",
        AvatarUrl = "https://cdn.sync.local/avatars/demo-user.png",
    };

    public static AuthorSnapshot Admin => new()
    {
        FullName = "SYNC Admin",
        AvatarUrl = "https://cdn.sync.local/avatars/admin.png",
    };

    public static AuthorSnapshot Partner => new()
    {
        FullName = "SYNC Partner",
        AvatarUrl = "https://cdn.sync.local/avatars/partner.png",
    };
}
