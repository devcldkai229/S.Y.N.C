using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class TargetAdjustmentLogRepository : ITargetAdjustmentLogRepository
{
    private readonly IamDbContext _dbContext;

    public TargetAdjustmentLogRepository(IamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task CreateAsync(TargetAdjustmentLog log, CancellationToken cancellationToken = default)
    {
        await _dbContext.Set<TargetAdjustmentLog>().AddAsync(log, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<TargetAdjustmentLog>> GetRecentAsync(
        Guid userId,
        int limit = 20,
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<TargetAdjustmentLog>()
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit)
            .ToListAsync(cancellationToken);
    }
}
