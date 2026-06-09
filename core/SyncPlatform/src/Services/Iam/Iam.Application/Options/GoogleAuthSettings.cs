namespace Iam.Application.Options;

public class GoogleAuthSettings
{
    public const string SectionName = "GoogleAuth";

    /// <summary>
    /// OAuth 2.0 Client IDs whose value may appear in the ID token <c>aud</c> claim
    /// (Web, Android, iOS from Google Cloud Console).
    /// </summary>
    public string[] ClientIds { get; set; } = [];

    /// <summary>Legacy single Client ID. Merged with <see cref="ClientIds"/> when set.</summary>
    public string ClientId { get; set; } = string.Empty;

    public IReadOnlyList<string> GetAllowedClientIds()
    {
        var ids = new List<string>();

        foreach (var id in ClientIds)
        {
            if (!string.IsNullOrWhiteSpace(id))
                ids.Add(id.Trim());
        }

        if (!string.IsNullOrWhiteSpace(ClientId))
        {
            var legacy = ClientId.Trim();
            if (!ids.Contains(legacy, StringComparer.Ordinal))
                ids.Add(legacy);
        }

        return ids;
    }
}
