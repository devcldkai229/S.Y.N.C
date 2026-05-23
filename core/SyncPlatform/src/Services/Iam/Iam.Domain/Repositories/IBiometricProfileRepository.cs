using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IBiometricProfileRepository
{
    Task<BiometricProfile?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task CreateAsync(BiometricProfile profile, CancellationToken cancellationToken = default);
    Task UpdateAsync(BiometricProfile profile, CancellationToken cancellationToken = default);
}
