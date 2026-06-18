using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Application.Helpers;

public static class PostVisibilityHelper
{
    public static bool CanView(
        Post post,
        Guid? viewerUserId,
        PrivacyType authorProfilePrivacy,
        bool isAcceptedFollower,
        bool isBlocked)
    {
        if (isBlocked)
            return false;

        if (viewerUserId.HasValue && post.AuthorId == viewerUserId.Value)
            return true;

        if (!post.IsPublic)
            return false;

        return authorProfilePrivacy switch
        {
            PrivacyType.Public => true,
            PrivacyType.Followers => isAcceptedFollower,
            PrivacyType.Private => false,
            _ => false,
        };
    }
}
