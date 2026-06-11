using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IUserSocialSettingsRepository
{
    Task<PrivacyType> GetProfilePrivacyAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<UserSocialSettings?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
}
