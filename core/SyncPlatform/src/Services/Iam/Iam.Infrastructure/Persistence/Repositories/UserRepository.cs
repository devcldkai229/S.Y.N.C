using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IamDbContext _db;

    public UserRepository(IamDbContext db) => _db = db;

    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Users.FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public async Task<IReadOnlyList<User>> GetAllForAdminAsync(
        string? search,
        UserRole? role,
        UserStatus? status,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Users.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                u.Email.ToLower().Contains(term) ||
                u.FullName.ToLower().Contains(term));
        }

        if (role.HasValue)
            query = query.Where(u => u.Role == role.Value);

        if (status.HasValue)
            query = query.Where(u => u.Status == status.Value);

        return await query
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public Task<User?> GetByIdWithBiometricAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Users
            .Include(u => u.BiometricProfile)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByIdWithOnboardingProfilesAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Users
            .Include(u => u.BiometricProfile)
            .Include(u => u.UserPreference)
            .Include(u => u.AIContextProfile)
            .Include(u => u.GamificationProfile)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByIdForPublicProfileAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Users
            .AsNoTracking()
            .Include(u => u.GamificationProfile)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default) =>
        _db.Users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);

    public Task<User?> GetByEmailVerificationTokenAsync(string token, CancellationToken cancellationToken = default) =>
        _db.Users.FirstOrDefaultAsync(u => u.EmailVerificationToken == token, cancellationToken);

    public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default) =>
        _db.Users.AnyAsync(u => u.Email == email, cancellationToken);

    public async Task AddAsync(User user, CancellationToken cancellationToken = default) =>
        await _db.Users.AddAsync(user, cancellationToken);

    public async Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        _db.Users.Update(user);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _db.SaveChangesAsync(cancellationToken);
}
