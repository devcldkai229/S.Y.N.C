using Iam.Domain.Enums;
using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Admin listing — optional free-text (name/email) + role/status filters, newest first.</summary>
    Task<IReadOnlyList<User>> GetAllForAdminAsync(
        string? search,
        UserRole? role,
        UserStatus? status,
        CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailVerificationTokenAsync(string token, CancellationToken cancellationToken = default);
    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default);
    Task AddAsync(User user, CancellationToken cancellationToken = default);
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task<User?> GetByIdWithBiometricAsync(Guid id, CancellationToken cancellationToken = default);

    Task<User?> GetByIdWithOnboardingProfilesAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>User + gamification only — for public profile (no biometrics/preferences).</summary>
    Task<User?> GetByIdForPublicProfileAsync(Guid id, CancellationToken cancellationToken = default);
    Task UpdateAsync(User user, CancellationToken cancellationToken = default);
}
