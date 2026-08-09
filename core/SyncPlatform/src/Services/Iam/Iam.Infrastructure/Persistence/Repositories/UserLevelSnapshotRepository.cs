using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class UserLevelSnapshotRepository : IUserLevelSnapshotRepository
{
    private readonly IamDbContext _dbContext;

    public UserLevelSnapshotRepository(IamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task CreateAsync(UserLevelSnapshot snapshot, CancellationToken cancellationToken = default)
    {
        await _dbContext.Set<UserLevelSnapshot>().AddAsync(snapshot, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<UserLevelSnapshot?> GetLatestAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<UserLevelSnapshot>()
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.ComputedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }
}
