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
    private readonly IIamGamificationClient _gamification;
    private readonly ISocialNotificationClient _notifications;
    private readonly IMediaUrlResolver _media;

    public PostService(
        IPostRepository posts,
        IPostEngagementRepository engagement,
        IUserFollowRepository follows,
        IUserSocialSettingsRepository socialSettings,
        IIamGamificationClient gamification,
        ISocialNotificationClient notifications,
        IMediaUrlResolver media)
    {
        _posts = posts;
        _engagement = engagement;
        _follows = follows;
        _socialSettings = socialSettings;
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

    public async Task<CursorFeedResult<PostDto>> GetPublicFeedCursorAsync(
        FeedCursorQuery query,
        CancellationToken cancellationToken = default)
    {
        var limit = NormalizeFeedLimit(query.Limit);
        var fetchSize = limit + 1;

        var batch = await _posts.GetPublicFeedCursorAsync(
            query.Cursor,
            fetchSize,
            cancellationToken);

        var hasMore = batch.Count > limit;
        var page = hasMore ? batch.Take(limit).ToList() : batch.ToList();

        string? nextCursor = null;
        if (hasMore && page.Count > 0)
            nextCursor = page[^1].CreatedAt.ToString("O");

        HashSet<Guid> likedIds = [];
        if (query.ViewerUserId.HasValue && page.Count > 0)
            likedIds = await _engagement.GetLikedPostIdsAsync(query.ViewerUserId.Value, page.Select(p => p.Id), cancellationToken);

        return new CursorFeedResult<PostDto>
        {
            Items = page.Select(x => x.ToDto(likedIds.Contains(x.Id), _media)).ToList(),
            NextCursor = nextCursor,
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

        var batch = await _posts.GetUserWallCursorAsync(
            authorId,
            query.Cursor,
            fetchSize,
            query.OnlyMedia,
            includePrivatePosts,
            cancellationToken);

        var hasMore = batch.Count > limit;
        var page = hasMore ? batch.Take(limit).ToList() : batch.ToList();

        string? nextCursor = null;
        if (hasMore && page.Count > 0)
            nextCursor = page[^1].CreatedAt.ToString("O");

        return new CursorFeedResult<PostDto>
        {
            Items = page.Select(x => x.ToDto(media: _media)).ToList(),
            NextCursor = nextCursor,
        };
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
            var batch = await _posts.SearchByTextAsync(query, rawSkip, SearchBatchSize, cancellationToken);
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
