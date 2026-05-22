namespace Iam.Application.Options;

public class GoogleAuthSettings
{
    public const string SectionName = "GoogleAuth";

    /// <summary>The OAuth 2.0 Client ID used by the Flutter app. Verified as the `aud` claim of the ID token.</summary>
    public string ClientId { get; set; } = string.Empty;
}
