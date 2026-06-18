using Social.Domain.Enums;

namespace Social.Domain.Models;

/// <summary>
/// Per-user social privacy settings stored in the Social service.
/// When absent, the profile is treated as <see cref="PrivacyType.Public"/>.
/// </summary>
public class UserSocialSettings : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public PrivacyType ProfilePrivacy { get; set; } = PrivacyType.Public;
}
