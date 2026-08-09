using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class BiometricHistoryRepository : IBiometricHistoryRepository
{
    private readonly IamDbContext _dbContext;

    public BiometricHistoryRepository(IamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task CreateAsync(BiometricHistory entry, CancellationToken cancellationToken = default)
    {
        await _dbContext.Set<BiometricHistory>().AddAsync(entry, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<BiometricHistory>> GetByUserIdAsync(
        Guid userId,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<BiometricHistory>()
            .Where(b => b.UserId == userId && b.RecordedAtUtc >= fromUtc && b.RecordedAtUtc <= toUtc)
            .OrderBy(b => b.RecordedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<BiometricHistory?> GetLatestAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<BiometricHistory>()
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.RecordedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);
    }
}
