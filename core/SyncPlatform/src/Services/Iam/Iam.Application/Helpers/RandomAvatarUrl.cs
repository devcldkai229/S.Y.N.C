namespace Iam.Application.Helpers;

/// <summary>
/// Builds avatar URLs compatible with the Flutter <c>random_avatar</c> package (Multiavatar).
/// The stored seed is passed to <c>RandomAvatar(seed)</c> on the client.
/// </summary>
public static class RandomAvatarUrl
{
    public const string Prefix = "randomavatar:";

    /// <summary>
    /// Creates a deterministic Multiavatar seed URL for a newly registered user.
    /// Email is used as the seed so the avatar stays stable across registration retries.
    /// </summary>
    public static string ForRegistration(string email, string? fullName = null)
    {
        var seed = email.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(seed) && !string.IsNullOrWhiteSpace(fullName))
            seed = fullName.Trim();

        return $"{Prefix}{seed}";
    }
}
