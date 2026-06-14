using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class UserSocialSettingsRepository : IUserSocialSettingsRepository
{
    private readonly IMongoCollection<UserSocialSettings> _collection;

    public UserSocialSettingsRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<UserSocialSettings>("UserSocialSettings");
    }

    public async Task<PrivacyType> GetProfilePrivacyAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var settings = await GetByUserIdAsync(userId, cancellationToken);
        return settings?.ProfilePrivacy ?? PrivacyType.Public;
    }

    public Task<UserSocialSettings?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        return _collection.Find(x => x.UserId == userId).FirstOrDefaultAsync(cancellationToken)!;
    }
}
