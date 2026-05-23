using Iam.Domain.Models;

namespace Iam.Application.Abstractions;

public interface IUserMeRepository
{
    Task<User?> GetUserWithProfilesAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<User> GetUserForUpdateAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserVoucher>> GetVouchersAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserAchievement>> GetAchievementsAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<GamificationProfile?> GetGamificationAsync(Guid userId, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
