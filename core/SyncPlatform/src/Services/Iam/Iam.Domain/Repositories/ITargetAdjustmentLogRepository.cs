using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface ITargetAdjustmentLogRepository
{
    Task CreateAsync(TargetAdjustmentLog log, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<TargetAdjustmentLog>> GetRecentAsync(
        Guid userId,
        int limit = 20,
        CancellationToken cancellationToken = default);
}
