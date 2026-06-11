namespace Social.Domain.Exceptions;

public sealed class DuplicateChallengeJoinException : Exception
{
    public Guid ChallengeId { get; }
    public Guid UserId { get; }

    public DuplicateChallengeJoinException(Guid challengeId, Guid userId)
        : base($"User {userId} has already joined challenge {challengeId}.")
    {
        ChallengeId = challengeId;
        UserId = userId;
    }
}
