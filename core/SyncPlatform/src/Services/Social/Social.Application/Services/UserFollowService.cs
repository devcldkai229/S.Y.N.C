using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class UserFollowService : IUserFollowService
{
    private const int MaxPageSize = 50;

    private readonly IUserFollowRepository _follows;
    private readonly IUserSocialSettingsRepository _socialSettings;
    private readonly ISocialNotificationClient _notifications;

    public UserFollowService(
        IUserFollowRepository follows,
        IUserSocialSettingsRepository socialSettings,
        ISocialNotificationClient notifications)
    {
        _follows = follows;
        _socialSettings = socialSettings;
        _notifications = notifications;
    }

    public async Task<UserFollowDto> FollowAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        EnsureNotSelf(followerId, followeeId);
        await EnsureNotBlockedAsync(followerId, followeeId, cancellationToken);

        var existing = await _follows.GetByPairAsync(followerId, followeeId, cancellationToken);
        if (existing is not null)
        {
            throw existing.Status switch
            {
                FollowStatus.Blocked => new ForbiddenException("You cannot follow this user."),
                FollowStatus.Accepted => new ConflictException("You are already following this user."),
                FollowStatus.Pending => new ConflictException("A follow request is already pending."),
                _ => new ConflictException("A follow relationship already exists."),
            };
        }

        var privacy = await _socialSettings.GetProfilePrivacyAsync(followeeId, cancellationToken);
        var status = privacy == PrivacyType.Private
            ? FollowStatus.Pending
            : FollowStatus.Accepted;

        var follow = new UserFollow
        {
            FollowerId = followerId,
            FolloweeId = followeeId,
            Status = status,
            FollowedAt = DateTimeOffset.UtcNow,
        };

        var saved = await _follows.UpsertAsync(follow, cancellationToken);

        if (status == FollowStatus.Pending)
        {
            _ = _notifications.NotifyFollowRequestedAsync(followerId, followeeId, cancellationToken);
        }
        else
        {
            _ = _notifications.NotifyNewFollowerAsync(followerId, followeeId, cancellationToken);
        }

        return saved.ToDto();
    }

    public async Task UnfollowAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default)
    {
        EnsureNotSelf(followerId, followeeId);

        var deleted = await _follows.DeleteByPairAsync(followerId, followeeId, cancellationToken);
        if (!deleted)
            throw new NotFoundException("Follow relationship was not found.");
    }

    public async Task<UserFollowDto> AcceptFollowRequestAsync(
        Guid followeeId,
        Guid followerId,
        CancellationToken cancellationToken = default)
    {
        EnsureNotSelf(followerId, followeeId);

        var existing = await _follows.GetByPairAsync(followerId, followeeId, cancellationToken)
            ?? throw new NotFoundException("Follow request was not found.");

        if (existing.Status == FollowStatus.Blocked)
            throw new ForbiddenException("This follow request cannot be accepted.");

        if (existing.Status != FollowStatus.Pending)
            throw new ConflictException("Only pending follow requests can be accepted.");

        await _follows.UpdateStatusAsync(followerId, followeeId, FollowStatus.Accepted, cancellationToken);
        existing.Status = FollowStatus.Accepted;
        existing.UpdatedAt = DateTimeOffset.UtcNow;

        _ = _notifications.NotifyFollowAcceptedAsync(
            followeeId,
            followerId,
            cancellationToken);

        return existing.ToDto();
    }

    public async Task RejectFollowRequestAsync(
        Guid followeeId,
        Guid followerId,
        CancellationToken cancellationToken = default)
    {
        EnsureNotSelf(followerId, followeeId);

        var existing = await _follows.GetByPairAsync(followerId, followeeId, cancellationToken)
            ?? throw new NotFoundException("Follow request was not found.");

        if (existing.Status != FollowStatus.Pending)
            throw new ConflictException("Only pending follow requests can be rejected.");

        await _follows.DeleteByPairAsync(followerId, followeeId, cancellationToken);
    }

    public async Task<UserFollowDto> BlockUserAsync(
        Guid blockerId,
        Guid blockedUserId,
        CancellationToken cancellationToken = default)
    {
        EnsureNotSelf(blockerId, blockedUserId);

        await _follows.DeleteByPairAsync(blockerId, blockedUserId, cancellationToken);
        await _follows.DeleteByPairAsync(blockedUserId, blockerId, cancellationToken);

        var block = new UserFollow
        {
            FollowerId = blockerId,
            FolloweeId = blockedUserId,
            Status = FollowStatus.Blocked,
            FollowedAt = DateTimeOffset.UtcNow,
        };

        var saved = await _follows.UpsertAsync(block, cancellationToken);
        return saved.ToDto();
    }

    public async Task<(IReadOnlyList<UserFollowDto> Items, PaginationMetadata Pagination)> GetFollowersAsync(
        Guid userId,
        FollowListQuery query,
        CancellationToken cancellationToken = default)
    {
        var (pageNumber, pageSize) = NormalizePaging(query);
        var (items, total) = await _follows.GetFollowersAsync(userId, pageNumber, pageSize, cancellationToken);

        return (
            items.Select(x => x.ToDto()).ToList(),
            BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<(IReadOnlyList<UserFollowDto> Items, PaginationMetadata Pagination)> GetFollowingAsync(
        Guid userId,
        FollowListQuery query,
        CancellationToken cancellationToken = default)
    {
        var (pageNumber, pageSize) = NormalizePaging(query);
        var (items, total) = await _follows.GetFollowingAsync(userId, pageNumber, pageSize, cancellationToken);

        return (
            items.Select(x => x.ToDto()).ToList(),
            BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<FollowStatusDto> GetFollowStatusAsync(
        Guid viewerUserId,
        Guid targetUserId,
        CancellationToken cancellationToken = default)
    {
        if (viewerUserId == targetUserId)
        {
            return new FollowStatusDto
            {
                ViewerUserId = viewerUserId,
                TargetUserId = targetUserId,
                OutgoingStatus = null,
                HasIncomingPendingRequest = false,
                IsBlockedBetween = false,
                CanFollow = false,
                CanViewContent = true,
            };
        }

        var isBlocked = await _follows.IsBlockedBetweenAsync(viewerUserId, targetUserId, cancellationToken);
        var outgoing = await _follows.GetByPairAsync(viewerUserId, targetUserId, cancellationToken);
        var incoming = await _follows.GetByPairAsync(targetUserId, viewerUserId, cancellationToken);

        var privacy = await _socialSettings.GetProfilePrivacyAsync(targetUserId, cancellationToken);
        var isAcceptedFollower = outgoing?.Status == FollowStatus.Accepted;
        var canView = !isBlocked && (privacy == PrivacyType.Public || isAcceptedFollower || viewerUserId == targetUserId);

        return new FollowStatusDto
        {
            ViewerUserId = viewerUserId,
            TargetUserId = targetUserId,
            OutgoingStatus = outgoing?.Status,
            HasIncomingPendingRequest = incoming?.Status == FollowStatus.Pending,
            IsBlockedBetween = isBlocked,
            CanFollow = !isBlocked && outgoing is null,
            CanViewContent = canView,
        };
    }

    public async Task<FollowCountsDto> GetFollowCountsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var followerCount = await _follows.CountFollowersAsync(userId, cancellationToken);
        var followingCount = await _follows.CountFollowingAsync(userId, cancellationToken);

        return new FollowCountsDto
        {
            UserId = userId,
            FollowerCount = followerCount,
            FollowingCount = followingCount,
        };
    }

    private static void EnsureNotSelf(Guid followerId, Guid followeeId)
    {
        if (followerId == followeeId)
            throw new BadRequestException("You cannot perform this action on yourself.");
    }

    private async Task EnsureNotBlockedAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken)
    {
        if (await _follows.IsBlockedBetweenAsync(followerId, followeeId, cancellationToken))
            throw new ForbiddenException("You cannot follow this user.");
    }

    private static (int PageNumber, int PageSize) NormalizePaging(FollowListQuery query)
    {
        var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
        var pageSize = query.PageSize < 1 ? 20 : Math.Min(query.PageSize, MaxPageSize);
        return (pageNumber, pageSize);
    }

    private static PaginationMetadata BuildPagination(int pageNumber, int pageSize, int totalRecords) =>
        new()
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = totalRecords,
        };
}
