using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IBiometricHistoryRepository
{
    Task CreateAsync(BiometricHistory entry, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<BiometricHistory>> GetByUserIdAsync(
        Guid userId,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken = default);

    Task<BiometricHistory?> GetLatestAsync(Guid userId, CancellationToken cancellationToken = default);
}
