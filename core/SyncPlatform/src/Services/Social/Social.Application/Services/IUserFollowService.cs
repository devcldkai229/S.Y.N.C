using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IUserFollowService
{
    Task<UserFollowDto> FollowAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task UnfollowAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task<UserFollowDto> AcceptFollowRequestAsync(
        Guid followeeId,
        Guid followerId,
        CancellationToken cancellationToken = default);

    Task RejectFollowRequestAsync(
        Guid followeeId,
        Guid followerId,
        CancellationToken cancellationToken = default);

    Task<UserFollowDto> BlockUserAsync(
        Guid blockerId,
        Guid blockedUserId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<UserFollowDto> Items, PaginationMetadata Pagination)> GetFollowersAsync(
        Guid userId,
        FollowListQuery query,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<UserFollowDto> Items, PaginationMetadata Pagination)> GetFollowingAsync(
        Guid userId,
        FollowListQuery query,
        CancellationToken cancellationToken = default);

    Task<FollowStatusDto> GetFollowStatusAsync(
        Guid viewerUserId,
        Guid targetUserId,
        CancellationToken cancellationToken = default);

    Task<FollowCountsDto> GetFollowCountsAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
