using System.Net.Http.Json;
using Social.Application.Clients;

namespace Social.Infrastructure.Clients;

public sealed class SocialNotificationClient : ISocialNotificationClient
{
    private readonly HttpClient _http;

    public SocialNotificationClient(HttpClient http) => _http = http;

    public Task NotifyPostLikedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        CancellationToken cancellationToken = default) =>
        SendAsync(actorId, targetUserId, postId, commentId: null, "PostLiked", cancellationToken);

    public Task NotifyPostCommentedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        Guid commentId,
        CancellationToken cancellationToken = default) =>
        SendAsync(actorId, targetUserId, postId, commentId, "PostCommented", cancellationToken);

    public Task NotifyCommentRepliedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        Guid commentId,
        CancellationToken cancellationToken = default) =>
        SendAsync(actorId, targetUserId, postId, commentId, "CommentReplied", cancellationToken);

    public Task NotifyFollowAcceptedAsync(
        Guid actorId,
        Guid targetUserId,
        CancellationToken cancellationToken = default) =>
        SendFollowAsync(actorId, targetUserId, "FollowAccepted", cancellationToken);

    public Task NotifyFollowRequestedAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default) =>
        SendFollowAsync(followerId, followeeId, "FollowRequested", cancellationToken);

    public Task NotifyNewFollowerAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default) =>
        SendFollowAsync(followerId, followeeId, "NewFollower", cancellationToken);

    public async Task NotifyNewPostToFollowersAsync(
        Guid authorId,
        string authorDisplayName,
        Guid postId,
        IReadOnlyList<Guid> followerUserIds,
        CancellationToken cancellationToken = default)
    {
        if (followerUserIds.Count == 0)
            return;

        var who = string.IsNullOrWhiteSpace(authorDisplayName) ? "Người bạn theo dõi" : authorDisplayName.Trim();

        foreach (var followerId in followerUserIds.Distinct())
        {
            if (followerId == authorId)
                continue;

            try
            {
                var payload = new
                {
                    actorId = authorId,
                    targetUserId = followerId,
                    postId,
                    type = "NewPostFromFollowing",
                };

                await _http.PostAsJsonAsync(
                    "/api/internal/notifications/send",
                    new
                    {
                        userId = followerId,
                        type = "NewPostFromFollowing",
                        channel = "InApp",
                        priority = "Normal",
                        title = "📣 Bài viết mới",
                        body = $"{who} vừa đăng bài viết mới. Xem ngay trên bảng tin SYNC.",
                        deepLink = $"/social/post/{postId}",
                        dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                    },
                    cancellationToken);
            }
            catch
            {
                // best-effort
            }
        }
    }

    public Task NotifyStoryViewedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid storyId,
        CancellationToken cancellationToken = default) =>
        SendStoryAsync(actorId, targetUserId, storyId, "StoryViewed", cancellationToken);

    public Task NotifyStoryLikedAsync(
        Guid actorId,
        Guid targetUserId,
        Guid storyId,
        CancellationToken cancellationToken = default) =>
        SendStoryAsync(actorId, targetUserId, storyId, "StoryLiked", cancellationToken);

    public async Task NotifyChallengeRewardEarnedAsync(
        Guid userId,
        Guid challengeId,
        string challengeTitle,
        decimal? pointRewards,
        string[]? gifts,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var giftList = gifts?.Where(g => !string.IsNullOrWhiteSpace(g)).ToArray() ?? [];
            var rewardParts = new List<string>();
            if (pointRewards is > 0)
                rewardParts.Add($"{pointRewards:0.##} điểm");
            if (giftList.Length > 0)
                rewardParts.Add(string.Join(", ", giftList));

            var rewardText = rewardParts.Count > 0
                ? string.Join(" + ", rewardParts)
                : "phần thưởng thử thách";

            var payload = new
            {
                userId,
                challengeId,
                challengeTitle,
                pointRewards,
                gifts = giftList,
                type = "ChallengeRewardEarned",
            };

            await _http.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId,
                    type = "ChallengeRewardEarned",
                    channel = "InApp",
                    priority = "Normal",
                    title = "🏆 Hoàn thành thử thách!",
                    body = $"Bạn đã hoàn thành «{challengeTitle}». Phần thưởng: {rewardText}.",
                    deepLink = $"/challenges/{challengeId}",
                    dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                },
                cancellationToken);
        }
        catch
        {
            // Notification is best-effort
        }
    }

    public async Task NotifyChallengeCompletedAsync(
        Guid challengeId,
        string challengeTitle,
        IReadOnlyList<Guid> participantUserIds,
        CancellationToken cancellationToken = default)
    {
        if (participantUserIds.Count == 0)
            return;

        foreach (var userId in participantUserIds.Distinct())
        {
            try
            {
                var payload = new { challengeId, challengeTitle, type = "ChallengeCompleted" };

                await _http.PostAsJsonAsync(
                    "/api/internal/notifications/send",
                    new
                    {
                        userId,
                        type = "ChallengeCompleted",
                        channel = "InApp",
                        priority = "Normal",
                        title = "🏁 Thử thách đã kết thúc",
                        body = $"Thử thách «{challengeTitle}» đã hoàn thành. Xem kết quả của bạn nhé!",
                        deepLink = $"/challenges/{challengeId}",
                        dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                    },
                    cancellationToken);
            }
            catch
            {
                // Notification is best-effort
            }
        }
    }

    private async Task SendStoryAsync(
        Guid actorId,
        Guid targetUserId,
        Guid storyId,
        string type,
        CancellationToken cancellationToken)
    {
        if (actorId == targetUserId)
            return;

        try
        {
            var payload = new { actorId, targetUserId, storyId, type };

            var (title, body) = type switch
            {
                "StoryViewed" => ("👀 Story được xem", "Ai đó vừa xem story của bạn."),
                "StoryLiked" => ("❤️ Story được thích", "Ai đó vừa thích story của bạn."),
                _ => ("Thông báo mới", "Bạn có hoạt động mới trên story."),
            };

            await _http.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId = targetUserId,
                    type,
                    channel = "InApp",
                    priority = "Normal",
                    title,
                    body,
                    deepLink = $"/social/story/{storyId}",
                    dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                },
                cancellationToken);
        }
        catch
        {
            // Notification is best-effort
        }
    }

    private async Task SendFollowAsync(
        Guid actorId,
        Guid targetUserId,
        string type,
        CancellationToken cancellationToken)
    {
        if (actorId == targetUserId)
            return;

        try
        {
            var payload = new { actorId, targetUserId, type };

            var (title, body, notifyUserId) = type switch
            {
                "FollowAccepted" => (
                    "✅ Yêu cầu theo dõi được chấp nhận",
                    "Yêu cầu theo dõi của bạn đã được chấp nhận.",
                    targetUserId),
                "FollowRequested" => (
                    "👤 Yêu cầu theo dõi mới",
                    "Ai đó muốn theo dõi bạn. Xem hồ sơ để chấp nhận hoặc từ chối.",
                    targetUserId),
                "NewFollower" => (
                    "🎉 Người theo dõi mới",
                    "Ai đó vừa bắt đầu theo dõi bạn.",
                    targetUserId),
                _ => ("Thông báo mới", "Bạn có hoạt động theo dõi mới.", targetUserId),
            };

            await _http.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId = notifyUserId,
                    type,
                    channel = "InApp",
                    priority = "Normal",
                    title,
                    body,
                    deepLink = $"/social/user/{actorId}",
                    dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                },
                cancellationToken);
        }
        catch
        {
            // Notification is best-effort
        }
    }

    private async Task SendAsync(
        Guid actorId,
        Guid targetUserId,
        Guid postId,
        Guid? commentId,
        string type,
        CancellationToken cancellationToken)
    {
        if (actorId == targetUserId)
            return;

        try
        {
            var payload = new
            {
                actorId,
                targetUserId,
                postId,
                commentId,
                type,
            };

            var (title, body, deepLink) = type switch
            {
                "PostLiked" => ("❤️ Bài viết được thích", "Ai đó vừa thích bài viết của bạn.", $"/social/post/{postId}"),
                "PostCommented" => ("💬 Bình luận mới", "Ai đó vừa bình luận bài viết của bạn.", $"/social/post/{postId}"),
                "CommentReplied" => ("↩️ Trả lời bình luận", "Ai đó vừa trả lời bình luận của bạn.", $"/social/post/{postId}"),
                _ => ("Thông báo mới", "Bạn có hoạt động mới trên bảng tin.", $"/social/post/{postId}"),
            };

            await _http.PostAsJsonAsync(
                "/api/internal/notifications/send",
                new
                {
                    userId = targetUserId,
                    type,
                    channel = "InApp",
                    priority = "Normal",
                    title,
                    body,
                    deepLink,
                    dataPayloadJson = System.Text.Json.JsonSerializer.Serialize(payload),
                },
                cancellationToken);
        }
        catch
        {
            // Notification is best-effort — never fail the caller
        }
    }
}
