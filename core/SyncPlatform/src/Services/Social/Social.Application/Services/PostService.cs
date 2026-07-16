using Libs.Storage.Services;
using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Exceptions;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class PostService : IPostService
{
    private const int MaxPageSize = 50;
    private const int SearchBatchSize = 40;
    private const int MaxSearchRawBatches = 8;

    private readonly IPostRepository _posts;
    private readonly IPostEngagementRepository _engagement;
    private readonly IUserFollowRepository _follows;
    private readonly IUserSocialSettingsRepository _socialSettings;
    private readonly ITrendingPostRepository _trending;
    private readonly IIamGamificationClient _gamification;
    private readonly ISocialNotificationClient _notifications;
    private readonly IMediaUrlResolver _media;

    public PostService(
        IPostRepository posts,
        IPostEngagementRepository engagement,
        IUserFollowRepository follows,
        IUserSocialSettingsRepository socialSettings,
        ITrendingPostRepository trending,
        IIamGamificationClient gamification,
        ISocialNotificationClient notifications,
        IMediaUrlResolver media)
    {
        _posts = posts;
        _engagement = engagement;
        _follows = follows;
        _socialSettings = socialSettings;
        _trending = trending;
        _gamification = gamification;
        _notifications = notifications;
        _media = media;
    }

    public async Task<PostDto> CreateAsync(
        Guid authorId,
        CreatePostDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content) && dto.MediaUrls.Count == 0)
            throw new BadRequestException("Post must have content or at least one media URL.");

        if (dto.MediaUrls.Count > 0)
        {
            var (imageCount, videoCount) = PostMediaRules.CountByUrls(dto.MediaUrls);
            PostMediaRules.ValidateCounts(imageCount, videoCount);
        }

        if (string.IsNullOrWhiteSpace(dto.AuthorSnapshot.FullName))
            throw new BadRequestException("AuthorSnapshot.FullName is required.");

        var entity = new Post
        {
            AuthorId = authorId,
            AuthorSnapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            },
            PostType = dto.PostType,
            Content = dto.Content.Trim(),
            ContentNormalized = TextNormalize.Normalize(dto.Content),
            MediaUrls = dto.MediaUrls,
            ReferenceId = dto.ReferenceId,
            IsPublic = dto.IsPublic,
            Metrics = new PostMetrics(),
        };

        await ShareCodeGenerator.AssignUniqueToPostAsync(_posts, entity, cancellationToken);
        await _posts.CreateAsync(entity, cancellationToken);

        // Grant XP for posting (fire-and-forget, error swallowed in client)
        _ = _gamification.GrantXpAsync(authorId, 75, 20, "social.post.created", cancellationToken);

        if (entity.IsPublic)
        {
            _ = NotifyFollowersAboutNewPostAsync(
                authorId,
                entity.AuthorSnapshot.FullName,
                entity.Id,
                cancellationToken);
        }

        return entity.ToDto(media: _media);
    }

    private async Task NotifyFollowersAboutNewPostAsync(
        Guid authorId,
        string authorDisplayName,
        Guid postId,
        CancellationToken cancellationToken)
    {
        try
        {
            var followerIds = await _follows.GetAcceptedFollowerIdsAsync(authorId, cancellationToken);
            await _notifications.NotifyNewPostToFollowersAsync(
                authorId,
                authorDisplayName,
                postId,
                followerIds,
                cancellationToken);
        }
        catch
        {
            // best-effort fan-out
        }
    }

    public async Task<PostDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _posts.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException($"Post {id} was not found.");
        return entity.ToDto(media: _media);
    }

    public async Task<CursorFeedResult<PostDto>> GetFeedCursorAsync(
        FeedCursorQuery query,
        CancellationToken cancellationToken = default)
    {
        var limit = NormalizeFeedLimit(query.Limit);
        var type = query.Type;

        // Anonymous → discovery; authenticated default following
        if (!query.ViewerUserId.HasValue)
            type = FeedType.Discovery;

        return type == FeedType.Discovery
            ? await GetDiscoveryFeedAsync(query, limit, cancellationToken)
            : await GetFollowingFeedWithBackfillAsync(query, limit, cancellationToken);
    }

    private async Task<CursorFeedResult<PostDto>> GetFollowingFeedWithBackfillAsync(
        FeedCursorQuery query,
        int limit,
        CancellationToken cancellationToken)
    {
        FeedCursorCodec.TryDecode(query.Cursor, out var cursor);
        var fetchSize = limit + 1;

        var followeeIds = await _follows.GetAcceptedFolloweeIdsAsync(
            query.ViewerUserId!.Value,
            cancellationToken);
        var authorIds = followeeIds.Contains(query.ViewerUserId.Value)
            ? followeeIds.ToList()
            : followeeIds.Append(query.ViewerUserId.Value).ToList();

        var followingBatch = (await _posts.GetFollowingFeedCursorAsync(
            authorIds,
            cursor,
            fetchSize,
            cancellationToken)).ToList();

        // Cold-start / exhausted following → backfill from trending
        var usedBackfill = false;
        if (followingBatch.Count < fetchSize)
        {
            var seenIds = followingBatch.Select(p => p.Id).ToHashSet();
            var need = fetchSize - followingBatch.Count;
            var trending = await _trending.GetCursorAsync(null, null, need + 20, cancellationToken);
            foreach (var t in trending)
            {
                if (!seenIds.Add(t.PostId))
                    continue;
                followingBatch.Add(t.Snapshot);
                usedBackfill = true;
                if (followingBatch.Count >= fetchSize)
                    break;
            }
        }

        var hasMore = followingBatch.Count > limit;
        var page = hasMore ? followingBatch.Take(limit).ToList() : followingBatch;

        string? nextCursor = null;
        if (hasMore && page.Count > 0)
        {
            // After backfill, client should switch to discovery for subsequent pages —
            // still emit chrono cursor so following continues if more exist; discovery
            // fallback handles empty following on next request.
            nextCursor = FeedCursorCodec.Encode(page[^1]);
        }

        HashSet<Guid> likedIds = [];
        if (page.Count > 0)
        {
            likedIds = await _engagement.GetLikedPostIdsAsync(
                query.ViewerUserId.Value,
                page.Select(p => p.Id),
                cancellationToken);
        }

        _ = usedBackfill; // reserved for future discovery-cursor handoff

        return new CursorFeedResult<PostDto>
        {
            Items = page.Select(x => x.ToDto(likedIds.Contains(x.Id), _media)).ToList(),
            NextCursor = nextCursor,
            HasMore = hasMore,
        };
    }

    private async Task<CursorFeedResult<PostDto>> GetDiscoveryFeedAsync(
        FeedCursorQuery query,
        int limit,
        CancellationToken cancellationToken)
    {
        var fetchSize = limit + 1;
        double? scoreCursor = null;
        Guid? idCursor = null;
        if (FeedCursorCodec.TryDecodeScore(query.Cursor, out var score, out var id))
        {
            scoreCursor = score;
            idCursor = id;
        }

        var trending = await _trending.GetCursorAsync(scoreCursor, idCursor, fetchSize, cancellationToken);

        // Fallback to public chronological if trending empty (before first cron run)
        if (trending.Count == 0)
        {
            FeedCursorCodec.TryDecode(query.Cursor, out var chronoCursor);
            var publicBatch = await _posts.GetPublicFeedCursorAsync(chronoCursor, fetchSize, cancellationToken);
            return await ToCursorPageAsync(publicBatch, limit, query.ViewerUserId, chronological: true, cancellationToken);
        }

        var hasMore = trending.Count > limit;
        var page = hasMore ? trending.Take(limit).ToList() : trending.ToList();

        string? nextCursor = null;
        if (hasMore && page.Count > 0)
            nextCursor = FeedCursorCodec.EncodeScore(page[^1].Score, page[^1].Id);

        HashSet<Guid> likedIds = [];
        if (query.ViewerUserId.HasValue && page.Count > 0)
        {
            likedIds = await _engagement.GetLikedPostIdsAsync(
                query.ViewerUserId.Value,
                page.Select(p => p.PostId),
                cancellationToken);
        }

        return new CursorFeedResult<PostDto>
        {
            Items = page.Select(x => x.Snapshot.ToDto(likedIds.Contains(x.PostId), _media)).ToList(),
            NextCursor = nextCursor,
            HasMore = hasMore,
        };
    }

    private async Task<CursorFeedResult<PostDto>> ToCursorPageAsync(
        IReadOnlyList<Post> batch,
        int limit,
        Guid? viewerUserId,
        bool chronological,
        CancellationToken cancellationToken)
    {
        var hasMore = batch.Count > limit;
        var page = hasMore ? batch.Take(limit).ToList() : batch.ToList();

        string? nextCursor = null;
        if (hasMore && page.Count > 0)
            nextCursor = FeedCursorCodec.Encode(page[^1]);

        HashSet<Guid> likedIds = [];
        if (viewerUserId.HasValue && page.Count > 0)
            likedIds = await _engagement.GetLikedPostIdsAsync(viewerUserId.Value, page.Select(p => p.Id), cancellationToken);

        return new CursorFeedResult<PostDto>
        {
            Items = page.Select(x => x.ToDto(likedIds.Contains(x.Id), _media)).ToList(),
            NextCursor = nextCursor,
            HasMore = hasMore,
        };
    }

    public async Task<CursorFeedResult<PostDto>> GetUserWallCursorAsync(
        Guid userId,
        UserWallQuery query,
        CancellationToken cancellationToken = default) =>
        await GetWallCursorAsync(userId, query, includePrivatePosts: false, cancellationToken);

    public async Task<CursorFeedResult<PostDto>> GetMyWallCursorAsync(
        Guid ownerId,
        UserWallQuery query,
        CancellationToken cancellationToken = default) =>
        await GetWallCursorAsync(ownerId, query, includePrivatePosts: true, cancellationToken);

    private async Task<CursorFeedResult<PostDto>> GetWallCursorAsync(
        Guid authorId,
        UserWallQuery query,
        bool includePrivatePosts,
        CancellationToken cancellationToken)
    {
        var limit = NormalizeFeedLimit(query.Limit);
        var fetchSize = limit + 1;
        FeedCursorCodec.TryDecode(query.Cursor, out var cursor);

        var batch = await _posts.GetUserWallCursorAsync(
            authorId,
            cursor,
            fetchSize,
            query.OnlyMedia,
            includePrivatePosts,
            cancellationToken);

        return await ToCursorPageAsync(batch, limit, viewerUserId: null, chronological: true, cancellationToken);
    }

    public async Task<PostDto> GetByShareCodeAsync(string shareCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(shareCode))
            throw new BadRequestException("Share code is required.");

        var entity = await _posts.GetByShareCodeAsync(shareCode, cancellationToken)
            ?? throw new NotFoundException($"Post with share code '{shareCode}' was not found.");

        if (!entity.IsPublic)
            throw new NotFoundException($"Post with share code '{shareCode}' was not found.");

        return entity.ToDto(media: _media);
    }

    public async Task<LikePostResultDto> LikePostAsync(
        Guid userId,
        Guid postId,
        CancellationToken cancellationToken = default)
    {
        if (!await _posts.ExistsAsync(postId, cancellationToken))
            throw new NotFoundException($"Post {postId} was not found.");

        try
        {
            var interaction = await _engagement.LikePostAsync(postId, userId, cancellationToken);
            var post = await _posts.GetByIdAsync(postId, cancellationToken);

            if (post is not null)
            {
                _ = _notifications.NotifyPostLikedAsync(userId, post.AuthorId, postId, cancellationToken);
            }

            return new LikePostResultDto
            {
                InteractionId = interaction.Id,
                PostId = postId,
                LikeCount = post?.Metrics.LikeCount ?? 0,
            };
        }
        catch (DuplicateLikeException)
        {
            throw new ConflictException("You have already liked this post.");
        }
    }

    public async Task UnlikePostAsync(Guid userId, Guid postId, CancellationToken cancellationToken = default)
    {
        await _engagement.UnlikePostAsync(postId, userId, cancellationToken);
    }

    public async Task DeleteAsync(Guid authorId, Guid postId, CancellationToken cancellationToken = default)
    {
        var entity = await _posts.GetByIdAsync(postId, cancellationToken)
            ?? throw new NotFoundException($"Post {postId} was not found.");

        if (entity.AuthorId != authorId)
            throw new ForbiddenException("You can only delete your own posts.");

        await _posts.DeleteAsync(postId, cancellationToken);
    }

    public async Task<PagedResult<PostDto>> SearchPostsAsync(
        PostSearchRequest request,
        Guid? viewerUserId,
        CancellationToken cancellationToken = default)
    {
        var query = request.Query?.Trim() ?? string.Empty;
        if (query.Length < 2)
        {
            return new PagedResult<PostDto>
            {
                Items = [],
                Pagination = new PaginationMetadata { PageNumber = 1, PageSize = 20, TotalRecords = 0 },
            };
        }

        var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
        var pageSize = request.PageSize < 1 ? 20 : Math.Min(request.PageSize, MaxPageSize);
        var targetSkip = (pageNumber - 1) * pageSize;

        HashSet<Guid> blockedPeerIds = [];
        HashSet<Guid> acceptedFolloweeIds = [];
        if (viewerUserId.HasValue)
        {
            var blocked = await _follows.GetBlockedPeerIdsAsync(viewerUserId.Value, cancellationToken);
            blockedPeerIds = blocked.ToHashSet();
            var following = await _follows.GetAcceptedFolloweeIdsAsync(viewerUserId.Value, cancellationToken);
            acceptedFolloweeIds = following.ToHashSet();
        }

        var visible = new List<Post>();
        var rawSkip = 0;
        var hasMoreRaw = true;
        var batches = 0;

        while (visible.Count < targetSkip + pageSize && hasMoreRaw && batches < MaxSearchRawBatches)
        {
            var batch = await _posts.SearchByTextAsync(
                TextNormalize.Normalize(query).Length >= 2 ? TextNormalize.Normalize(query) : query,
                rawSkip,
                SearchBatchSize,
                cancellationToken);
            batches++;
            if (batch.Count == 0)
            {
                hasMoreRaw = false;
                break;
            }

            rawSkip += batch.Count;
            hasMoreRaw = batch.Count >= SearchBatchSize;

            var authorIds = batch
                .Select(p => p.AuthorId)
                .Distinct()
                .ToList();

            var privacyByAuthor = new Dictionary<Guid, PrivacyType>();
            foreach (var authorId in authorIds)
            {
                privacyByAuthor[authorId] = await _socialSettings.GetProfilePrivacyAsync(
                    authorId,
                    cancellationToken);
            }

            foreach (var post in batch)
            {
                var isBlocked = viewerUserId.HasValue && blockedPeerIds.Contains(post.AuthorId);
                var isFollower = viewerUserId.HasValue && acceptedFolloweeIds.Contains(post.AuthorId);
                var privacy = privacyByAuthor.GetValueOrDefault(post.AuthorId, PrivacyType.Public);

                if (!PostVisibilityHelper.CanView(post, viewerUserId, privacy, isFollower, isBlocked))
                    continue;

                visible.Add(post);
            }
        }

        var page = visible.Skip(targetSkip).Take(pageSize).ToList();

        HashSet<Guid> likedIds = [];
        if (viewerUserId.HasValue && page.Count > 0)
        {
            likedIds = await _engagement.GetLikedPostIdsAsync(
                viewerUserId.Value,
                page.Select(p => p.Id),
                cancellationToken);
        }

        var totalRecords = visible.Count;
        if (hasMoreRaw && visible.Count >= targetSkip + pageSize)
            totalRecords = Math.Max(totalRecords, pageNumber * pageSize + 1);

        return new PagedResult<PostDto>
        {
            Items = page.Select(x => x.ToDto(likedIds.Contains(x.Id), _media)).ToList(),
            Pagination = new PaginationMetadata
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalRecords = totalRecords,
            },
        };
    }

    private static int NormalizeFeedLimit(int limit) =>
        limit switch
        {
            < 1 => 20,
            > 50 => 50,
            _ => limit,
        };
}
