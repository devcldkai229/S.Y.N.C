using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class BiometricProfileRepository : IBiometricProfileRepository
{
    private readonly IamDbContext _dbContext;

    public BiometricProfileRepository(IamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<BiometricProfile?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.BiometricProfiles
            .FirstOrDefaultAsync(b => b.UserId == userId, cancellationToken);
    }

    public async Task CreateAsync(BiometricProfile profile, CancellationToken cancellationToken = default)
    {
        await _dbContext.BiometricProfiles.AddAsync(profile, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(BiometricProfile profile, CancellationToken cancellationToken = default)
    {
        _dbContext.BiometricProfiles.Update(profile);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
