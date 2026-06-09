using Iam.Domain.Models;

namespace Iam.Application.Abstractions;

public interface IUserMeRepository
{
    Task<User?> GetUserWithProfilesAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<User?> GetUserForUpdateAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserVoucher>> GetVouchersAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserAchievement>> GetAchievementsAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<GamificationProfile?> GetGamificationAsync(Guid userId, CancellationToken cancellationToken = default);

    // ── Achievement write support ──────────────────────────────────────────────

    Task<IReadOnlyList<Achievement>> GetAllAchievementsAsync(CancellationToken cancellationToken = default);

    Task<HashSet<Guid>> GetUnlockedAchievementIdsAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>Returns a tracked (non-read-only) GamificationProfile for mutation.</summary>
    Task<GamificationProfile?> GetGamificationForUpdateAsync(Guid userId, CancellationToken cancellationToken = default);

    void AddUserAchievement(UserAchievement ua);

    void AddVoucher(UserVoucher voucher);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
