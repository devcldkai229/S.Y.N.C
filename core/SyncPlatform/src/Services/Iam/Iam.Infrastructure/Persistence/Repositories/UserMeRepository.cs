using Iam.Application.Abstractions;
using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public sealed class UserMeRepository : IUserMeRepository
{
    private readonly IamDbContext _db;

    public UserMeRepository(IamDbContext db) => _db = db;

    public Task<User?> GetUserWithProfilesAsync(Guid userId, CancellationToken cancellationToken = default) =>
        _db.Users
            .AsNoTracking()
            .Include(u => u.BiometricProfile)
            .Include(u => u.UserPreference)
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

    public Task<User?> GetUserForUpdateAsync(Guid userId, CancellationToken cancellationToken = default) =>
        _db.Users
            .Include(u => u.BiometricProfile)
            .Include(u => u.UserPreference)
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

    public async Task<IReadOnlyList<UserVoucher>> GetVouchersAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await _db.UserVouchers
            .AsNoTracking()
            .Where(v => v.UserId == userId)
            .OrderByDescending(v => v.AcquiredAt)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<UserAchievement>> GetAchievementsAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await _db.UserAchievements
            .AsNoTracking()
            .Include(ua => ua.Achievement)
            .Where(ua => ua.UserId == userId)
            .OrderByDescending(ua => ua.UnlockedAt)
            .ToListAsync(cancellationToken);

    public Task<GamificationProfile?> GetGamificationAsync(Guid userId, CancellationToken cancellationToken = default) =>
        _db.GamificationProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(g => g.UserId == userId, cancellationToken);

    public async Task<IReadOnlyList<Achievement>> GetAllAchievementsAsync(CancellationToken cancellationToken = default) =>
        await _db.Achievements
            .AsNoTracking()
            .ToListAsync(cancellationToken);

    public async Task<HashSet<Guid>> GetUnlockedAchievementIdsAsync(Guid userId, CancellationToken cancellationToken = default) =>
        (await _db.UserAchievements
            .AsNoTracking()
            .Where(ua => ua.UserId == userId)
            .Select(ua => ua.AchievementId)
            .ToListAsync(cancellationToken))
        .ToHashSet();

    public Task<GamificationProfile?> GetGamificationForUpdateAsync(Guid userId, CancellationToken cancellationToken = default) =>
        _db.GamificationProfiles
            .FirstOrDefaultAsync(g => g.UserId == userId, cancellationToken);

    public void AddUserAchievement(UserAchievement ua) =>
        _db.UserAchievements.Add(ua);

    public void AddVoucher(UserVoucher voucher) =>
        _db.UserVouchers.Add(voucher);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _db.SaveChangesAsync(cancellationToken);
}
