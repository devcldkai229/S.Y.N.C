using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IUserFollowRepository
{
    Task<UserFollow?> GetByPairAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task<bool> IsBlockedBetweenAsync(
        Guid userA,
        Guid userB,
        CancellationToken cancellationToken = default);

    Task<UserFollow> UpsertAsync(UserFollow entity, CancellationToken cancellationToken = default);

    Task<bool> DeleteByPairAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<UserFollow> Items, int TotalRecords)> GetFollowersAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<UserFollow> Items, int TotalRecords)> GetFollowingAsync(
        Guid userId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<int> CountFollowersAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<int> CountFollowingAsync(Guid userId, CancellationToken cancellationToken = default);

    Task UpdateStatusAsync(
        Guid followerId,
        Guid followeeId,
        FollowStatus status,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Guid>> GetAcceptedFolloweeIdsAsync(
        Guid followerId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Guid>> GetAcceptedFollowerIdsAsync(
        Guid followeeId,
        CancellationToken cancellationToken = default);

    Task<bool> IsAcceptedFollowerAsync(
        Guid followerId,
        Guid followeeId,
        CancellationToken cancellationToken = default);
}
