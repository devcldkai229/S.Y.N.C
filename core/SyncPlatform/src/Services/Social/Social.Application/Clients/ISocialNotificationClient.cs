namespace Social.Application.Clients;

public interface ISocialNotificationClient
{
    Task NotifyPostLikedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        CancellationToken cancellationToken = default);

    Task NotifyPostCommentedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        Guid commentId,
        CancellationToken cancellationToken = default);

    Task NotifyCommentRepliedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        Guid commentId,
        CancellationToken cancellationToken = default);

    Task NotifyFollowAcceptedAsync(
        Guid actorId,
        Guid targetUserId,
        CancellationToken cancellationToken = default);

    Task NotifyFollowRequestedAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task NotifyNewFollowerAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task NotifyNewPostToFollowersAsync(
        Guid authorId,
        string authorDisplayName,
        Guid postId,
        IReadOnlyList<Guid> followerUserIds,
        CancellationToken cancellationToken = default);

    Task NotifyStoryViewedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid storyId,
        CancellationToken cancellationToken = default);

    Task NotifyStoryLikedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid storyId,
        CancellationToken cancellationToken = default);

    Task NotifyChallengeCompletedAsync(
        Guid challengeId,
        string challengeTitle,
        IReadOnlyList<Guid> participantUserIds,
        CancellationToken cancellationToken = default);

    Task NotifyChallengeRewardEarnedAsync(
        Guid userId,
        Guid challengeId,
        string challengeTitle,
        decimal? pointRewards,
        string[]? gifts,
        CancellationToken cancellationToken = default);
}
