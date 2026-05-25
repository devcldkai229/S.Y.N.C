using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IRecoveryProfileRepository : IGenericRepository<RecoveryProfile>
{
    Task<RecoveryProfile?> GetLatestByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
}
