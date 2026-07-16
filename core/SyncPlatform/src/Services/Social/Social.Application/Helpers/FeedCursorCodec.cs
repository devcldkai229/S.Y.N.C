using System.Text;
using System.Text.Json;
using Social.Domain.Models;

namespace Social.Application.Helpers;

/// <summary>
/// Compound keyset cursor: base64(JSON { createdAt, id }) with legacy ISO-8601 CreatedAt fallback.
/// </summary>
public static class FeedCursorCodec
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private sealed record WirePayload(DateTimeOffset CreatedAt, Guid Id);

    public static string Encode(DateTimeOffset createdAt, Guid id)
    {
        var json = JsonSerializer.Serialize(new WirePayload(createdAt, id), JsonOptions);
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(json));
    }

    public static string Encode(Post post) => Encode(post.CreatedAt, post.Id);

    public static string EncodeScore(double score, Guid id)
    {
        var json = JsonSerializer.Serialize(new { score, id }, JsonOptions);
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(json));
    }

    public static bool TryDecodeScore(string? raw, out double score, out Guid id)
    {
        score = 0;
        id = Guid.Empty;
        if (string.IsNullOrWhiteSpace(raw))
            return false;

        try
        {
            var json = Encoding.UTF8.GetString(Convert.FromBase64String(raw));
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("score", out var scoreEl))
                return false;
            score = scoreEl.GetDouble();
            if (doc.RootElement.TryGetProperty("id", out var idEl) &&
                Guid.TryParse(idEl.GetString(), out var parsed))
                id = parsed;
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static bool TryDecode(string? raw, out FeedCursorValue? cursor)
    {
        cursor = null;
        if (string.IsNullOrWhiteSpace(raw))
            return false;

        if (DateTimeOffset.TryParse(raw, out var legacyTs))
        {
            cursor = new FeedCursorValue(legacyTs, Guid.Empty);
            return true;
        }

        try
        {
            var json = Encoding.UTF8.GetString(Convert.FromBase64String(raw));
            var payload = JsonSerializer.Deserialize<WirePayload>(json, JsonOptions);
            if (payload is null)
                return false;
            cursor = new FeedCursorValue(payload.CreatedAt, payload.Id);
            return true;
        }
        catch
        {
            return false;
        }
    }
}
