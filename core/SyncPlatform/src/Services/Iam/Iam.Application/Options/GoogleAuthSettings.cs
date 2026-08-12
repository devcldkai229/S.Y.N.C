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

        void AddSplit(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return;

            foreach (var part in raw.Split([',', ';', ' ', '\n', '\r', '\t'],
                         StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                if (!ids.Contains(part, StringComparer.Ordinal))
                    ids.Add(part);
            }
        }

        foreach (var id in ClientIds)
            AddSplit(id);

        AddSplit(ClientId);

        return ids;
    }
}
