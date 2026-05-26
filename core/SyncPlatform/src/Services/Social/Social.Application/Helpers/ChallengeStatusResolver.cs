using Social.Domain.Enums;

namespace Social.Application.Helpers;

public static class ChallengeStatusResolver
{
    public static ChallengeStatus Resolve(DateTimeOffset startDate, DateTimeOffset endDate, DateTimeOffset? utcNow = null)
    {
        var now = utcNow ?? DateTimeOffset.UtcNow;
        if (now < startDate)
            return ChallengeStatus.Upcoming;
        if (now > endDate)
            return ChallengeStatus.Completed;
        return ChallengeStatus.Active;
    }
}
