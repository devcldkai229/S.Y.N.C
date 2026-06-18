using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Application.Helpers;

public static class ChallengeStatusResolver
{
    /// <summary>
    /// Active: created → registration deadline (open for join).
    /// Upcoming: registration deadline → start (closed, waiting).
    /// InProgress: start → end (event running).
    /// Completed: after end.
    /// </summary>
    public static ChallengeStatus Resolve(
        DateTimeOffset registrationDeadline,
        DateTimeOffset startDate,
        DateTimeOffset endDate,
        DateTimeOffset? utcNow = null)
    {
        var now = utcNow ?? DateTimeOffset.UtcNow;

        if (now > endDate)
            return ChallengeStatus.Completed;

        if (now >= startDate)
            return ChallengeStatus.InProgress;

        if (now >= registrationDeadline)
            return ChallengeStatus.Upcoming;

        return ChallengeStatus.Active;
    }

    public static ChallengeStatus Resolve(CommunityChallenge challenge, DateTimeOffset? utcNow = null) =>
        Resolve(challenge.RegistrationDeadline, challenge.StartDate, challenge.EndDate, utcNow);

    public static bool SyncStatus(CommunityChallenge challenge, DateTimeOffset? utcNow = null)
    {
        var resolved = Resolve(challenge, utcNow);
        if (challenge.Status == resolved)
            return false;

        challenge.Status = resolved;
        return true;
    }
}
