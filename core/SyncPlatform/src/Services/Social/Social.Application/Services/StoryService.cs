using Libs.Storage.Services;
using Social.Application.Clients;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class StoryService : IStoryService
{
    public static readonly TimeSpan StoryLifetime = TimeSpan.FromHours(24);

    private readonly IStoryRepository _stories;
    private readonly IStoryInteractionRepository _storyInteractions;
    private readonly IStoryViewRepository _storyViews;
    private readonly IUserFollowRepository _follows;
    private readonly IStorageService _storage;
    private readonly ISocialNotificationClient _notifications;
    private readonly IMediaUrlResolver _media;

    public StoryService(
        IStoryRepository stories,
        IStoryInteractionRepository storyInteractions,
        IStoryViewRepository storyViews,
        IUserFollowRepository follows,
        IStorageService storage,
        ISocialNotificationClient notifications,
        IMediaUrlResolver media)
    {
        _stories = stories;
        _storyInteractions = storyInteractions;
        _storyViews = storyViews;
        _follows = follows;
        _storage = storage;
        _notifications = notifications;
        _media = media;
    }

    public async Task<StoryDto> CreateAsync(
        Guid authorId,
        CreateStoryDto dto,
        Stream? mediaStream,
        long? mediaSize,
        string? fileName,
        string? contentType,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.AuthorSnapshot.FullName))
            throw new BadRequestException("AuthorSnapshot.FullName is required.");

        var mediaType = ResolveMediaType(mediaStream, contentType);
        if (mediaType == StoryMediaType.TextOnly &&
            string.IsNullOrWhiteSpace(dto.Caption))
        {
            throw new BadRequestException("Caption is required for text-only stories.");
        }

        string mediaUrl = string.Empty;
        if (mediaStream is not null)
        {
            var ext = Path.GetExtension(fileName ?? string.Empty);
            if (string.IsNullOrWhiteSpace(ext) && !string.IsNullOrWhiteSpace(contentType))
                ext = $".{contentType.Split('/').Last()}";

            var objectName = $"stories/{Guid.NewGuid():N}{ext}";
            var resolvedContentType = ResolveUploadContentType(contentType, objectName);

            mediaUrl = await _storage.UploadFileAsync(
                mediaStream,
                mediaSize,
                objectName,
                resolvedContentType,
                cancellationToken);
        }

        var now = DateTimeOffset.UtcNow;
        var story = new Story
        {
            AuthorId = authorId,
            AuthorSnapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            },
            MediaUrl = mediaUrl,
            MediaType = mediaType,
            Caption = string.IsNullOrWhiteSpace(dto.Caption) ? null : dto.Caption.Trim(),
            ExpiresAt = now.Add(StoryLifetime),
            Privacy = dto.Privacy,
            IsActive = true,
        };

        await _stories.CreateAsync(story, cancellationToken);
        return story.ToDto(isLikedByMe: false, media: _media);
    }

    public async Task<IReadOnlyList<StoryDto>> GetActiveByUserAsync(
        Guid authorId,
        Guid? viewerId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        var stories = await _stories.GetActiveByAuthorIdAsync(authorId, now, cancellationToken);
        var result = new List<StoryDto>();

        foreach (var story in stories)
        {
            if (!await CanViewStoryAsync(story, viewerId, cancellationToken))
                continue;

            var liked = viewerId.HasValue &&
                await _storyInteractions.HasLikedAsync(story.Id, viewerId.Value, cancellationToken);

            result.Add(story.ToDto(liked, _media));
        }

        return result;
    }

    public async Task<IReadOnlyList<StoryFeedGroupDto>> GetFeedAsync(
        Guid viewerId,
        CancellationToken cancellationToken = default)
    {
        var followeeIds = await _follows.GetAcceptedFolloweeIdsAsync(viewerId, cancellationToken);
        var authorIds = followeeIds.Contains(viewerId)
            ? followeeIds
            : followeeIds.Append(viewerId).ToList();

        if (authorIds.Count == 0)
            return [];

        var now = DateTimeOffset.UtcNow;
        var stories = await _stories.GetActiveByAuthorIdsAsync(authorIds, now, cancellationToken);
        var visible = new List<Story>();

        foreach (var story in stories)
        {
            if (await CanViewStoryAsync(story, viewerId, cancellationToken))
                visible.Add(story);
        }

        var groups = new List<StoryFeedGroupDto>();
        var allStoryIds = visible.Select(s => s.Id).ToList();
        var viewedIds = await _storyViews.GetViewedStoryIdsAsync(viewerId, allStoryIds, cancellationToken);

        foreach (var group in visible.GroupBy(x => x.AuthorId))
        {
            var ordered = group.OrderBy(x => x.CreatedAt).ToList();
            var first = ordered[0];
            var latest = ordered[^1];
            var storyDtos = new List<StoryDto>();

            foreach (var story in ordered)
            {
                var liked = await _storyInteractions.HasLikedAsync(story.Id, viewerId, cancellationToken);
                storyDtos.Add(story.ToDto(liked, _media));
            }

            var hasUnseen = ordered.Any(s => !viewedIds.Contains(s.Id));
            var cover = ordered.LastOrDefault(s => !string.IsNullOrWhiteSpace(s.MediaUrl)) ?? latest;

            groups.Add(new StoryFeedGroupDto
            {
                AuthorId = group.Key,
                AuthorSnapshot = new AuthorSnapshotDto
                {
                    FullName = first.AuthorSnapshot.FullName,
                    AvatarUrl = first.AuthorSnapshot.AvatarUrl,
                },
                StoryCount = storyDtos.Count,
                LatestAt = latest.CreatedAt,
                HasUnseen = hasUnseen,
                CoverThumbUrl = _media.ResolveForDisplay(cover.MediaUrl),
                Stories = storyDtos,
            });
        }

        // IG-style: self first → unseen (by latestAt) → seen (by latestAt)
        return groups
            .OrderByDescending(g => g.AuthorId == viewerId)
            .ThenByDescending(g => g.HasUnseen)
            .ThenByDescending(g => g.LatestAt)
            .ToList();
    }

    public async Task<StoryViewResultDto> ViewAsync(
        Guid viewerId,
        Guid storyId,
        CancellationToken cancellationToken = default)
    {
        var story = await _stories.GetByIdAsync(storyId, cancellationToken)
            ?? throw new NotFoundException($"Story {storyId} was not found.");

        if (!await CanViewStoryAsync(story, viewerId, cancellationToken))
            throw new ForbiddenException("You cannot view this story.");

        var isFirstView = await _storyViews.TryRecordViewAsync(storyId, viewerId, cancellationToken);
        if (isFirstView)
        {
            await _stories.IncrementViewCountAsync(storyId, cancellationToken);

            if (story.AuthorId != viewerId)
            {
                _ = _notifications.NotifyStoryViewedAsync(
                    viewerId,
                    story.AuthorId,
                    storyId,
                    cancellationToken);
            }
        }
        else
        {
            await _stories.IncrementViewCountAsync(storyId, cancellationToken);
        }

        var updated = await _stories.GetByIdAsync(storyId, cancellationToken);
        return new StoryViewResultDto
        {
            StoryId = storyId,
            ViewCount = updated?.ViewCount ?? story.ViewCount + 1,
            IsFirstView = isFirstView,
        };
    }

    public async Task<StoryLikeResultDto> LikeAsync(
        Guid userId,
        Guid storyId,
        CancellationToken cancellationToken = default)
    {
        var story = await _stories.GetByIdAsync(storyId, cancellationToken)
            ?? throw new NotFoundException($"Story {storyId} was not found.");

        if (!await CanViewStoryAsync(story, userId, cancellationToken))
            throw new ForbiddenException("You cannot like this story.");

        var interaction = new StoryInteraction
        {
            StoryId = storyId,
            UserId = userId,
            InteractionType = InteractionType.Like,
        };

        var created = await _storyInteractions.TryCreateAsync(interaction, cancellationToken);
        if (!created)
            throw new ConflictException("You have already liked this story.");

        await _stories.IncrementLikeCountAsync(storyId, cancellationToken);

        if (story.AuthorId != userId)
        {
            _ = _notifications.NotifyStoryLikedAsync(
                userId,
                story.AuthorId,
                storyId,
                cancellationToken);
        }

        var updated = await _stories.GetByIdAsync(storyId, cancellationToken);
        return new StoryLikeResultDto
        {
            StoryId = storyId,
            LikeCount = updated?.LikeCount ?? story.LikeCount + 1,
            IsLikedByMe = true,
        };
    }

    public async Task DeleteAsync(
        Guid authorId,
        Guid storyId,
        CancellationToken cancellationToken = default)
    {
        var deleted = await _stories.SoftDeleteAsync(storyId, authorId, cancellationToken);
        if (!deleted)
            throw new NotFoundException("Story was not found or you are not the author.");
    }

    private async Task<bool> CanViewStoryAsync(
        Story story,
        Guid? viewerId,
        CancellationToken cancellationToken)
    {
        if (viewerId is null)
        {
            return StoryPrivacyHelper.CanView(story, null, isAcceptedFollower: false, isBlocked: false);
        }

        if (await _follows.IsBlockedBetweenAsync(viewerId.Value, story.AuthorId, cancellationToken))
            return false;

        var isFollower = viewerId.Value == story.AuthorId ||
            await _follows.IsAcceptedFollowerAsync(viewerId.Value, story.AuthorId, cancellationToken);

        return StoryPrivacyHelper.CanView(story, viewerId, isFollower, isBlocked: false);
    }

    private static StoryMediaType ResolveMediaType(Stream? mediaStream, string? contentType)
    {
        if (mediaStream is null)
            return StoryMediaType.TextOnly;

        if (string.IsNullOrWhiteSpace(contentType))
            return StoryMediaType.Image;

        if (contentType.StartsWith("video/", StringComparison.OrdinalIgnoreCase))
            return StoryMediaType.Video;

        if (contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            return StoryMediaType.Image;

        return StoryMediaType.Image;
    }

    /// <summary>
    /// Prefer a concrete image/video MIME when clients send octet-stream or empty CT.
    /// </summary>
    private static string ResolveUploadContentType(string? contentType, string objectName)
    {
        if (!string.IsNullOrWhiteSpace(contentType) &&
            !contentType.Equals("application/octet-stream", StringComparison.OrdinalIgnoreCase))
        {
            return contentType;
        }

        var ext = Path.GetExtension(objectName).ToLowerInvariant();
        return ext switch
        {
            ".webp" => "image/webp",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".gif" => "image/gif",
            ".mp4" => "video/mp4",
            ".webm" => "video/webm",
            ".mov" => "video/quicktime",
            ".mpeg" or ".mpg" => "video/mpeg",
            _ => string.IsNullOrWhiteSpace(contentType) ? "application/octet-stream" : contentType,
        };
    }
}
