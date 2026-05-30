using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Exceptions;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class PostService : IPostService
{
    private readonly IPostRepository _posts;
    private readonly IPostEngagementRepository _engagement;
    private readonly IIamGamificationClient _gamification;

    public PostService(
        IPostRepository posts,
        IPostEngagementRepository engagement,
        IIamGamificationClient gamification)
    {
        _posts = posts;
        _engagement = engagement;
        _gamification = gamification;
    }

    public async Task<PostDto> CreateAsync(
        Guid authorId,
        CreatePostDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content) && dto.MediaUrls.Count == 0)
            throw new BadRequestException("Post must have content or at least one media URL.");

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

        return entity.ToDto();
    }

    public async Task<PostDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _posts.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException($"Post {id} was not found.");
        return entity.ToDto();
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
            Items = page.Select(x => x.ToDto(likedIds.Contains(x.Id))).ToList(),
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
            Items = page.Select(x => x.ToDto()).ToList(),
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

        return entity.ToDto();
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

    private static int NormalizeFeedLimit(int limit) =>
        limit switch
        {
            < 1 => 20,
            > 50 => 50,
            _ => limit,
        };
}
