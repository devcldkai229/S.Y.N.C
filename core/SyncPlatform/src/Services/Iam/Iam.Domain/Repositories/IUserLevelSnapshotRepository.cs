using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IUserLevelSnapshotRepository
{
    Task CreateAsync(UserLevelSnapshot snapshot, CancellationToken cancellationToken = default);

    Task<UserLevelSnapshot?> GetLatestAsync(Guid userId, CancellationToken cancellationToken = default);
}
