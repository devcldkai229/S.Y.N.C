namespace Social.Domain.Exceptions;

public class DuplicateLikeException : Exception
{
    public DuplicateLikeException(Guid postId, Guid userId)
        : base($"User {userId} has already liked post {postId}.")
    {
        PostId = postId;
        UserId = userId;
    }

    public Guid PostId { get; }
    public Guid UserId { get; }
}
