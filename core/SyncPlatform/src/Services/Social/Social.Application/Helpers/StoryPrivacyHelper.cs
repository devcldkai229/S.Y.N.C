using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Application.Helpers;

public static class StoryPrivacyHelper
{
    public static bool CanView(
        Story story,
        Guid? viewerId,
        bool isAcceptedFollower,
        bool isBlocked)
    {
        if (!story.IsActive || story.ExpiresAt <= DateTimeOffset.UtcNow)
            return false;

        if (isBlocked)
            return false;

        if (viewerId == story.AuthorId)
            return true;

        return story.Privacy switch
        {
            PrivacyType.Public => true,
            PrivacyType.Followers => isAcceptedFollower,
            PrivacyType.Private => false,
            _ => false,
        };
    }
}
