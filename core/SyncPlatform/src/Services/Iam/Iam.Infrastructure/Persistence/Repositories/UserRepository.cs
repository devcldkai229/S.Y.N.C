using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IamDbContext _db;

    public UserRepository(IamDbContext db)
    {
        _db = db;
    }

    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => _db.Users.FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
        => _db.Users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);

    public Task<User?> GetByEmailVerificationTokenAsync(string token, CancellationToken cancellationToken = default)
        => _db.Users.FirstOrDefaultAsync(u => u.EmailVerificationToken == token, cancellationToken);

    public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default)
        => _db.Users.AnyAsync(u => u.Email == email, cancellationToken);

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
        => await _db.Users.AddAsync(user, cancellationToken);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => _db.SaveChangesAsync(cancellationToken);
    private readonly IamDbContext _dbContext;

    public UserRepository(IamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Users
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<User?> GetByIdWithBiometricAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Users
            .Include(u => u.BiometricProfile)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task CreateAsync(User user, CancellationToken cancellationToken = default)
    {
        await _dbContext.Users.AddAsync(user, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        _dbContext.Users.Update(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Users.AnyAsync(u => u.Id == id, cancellationToken);
    }
}
