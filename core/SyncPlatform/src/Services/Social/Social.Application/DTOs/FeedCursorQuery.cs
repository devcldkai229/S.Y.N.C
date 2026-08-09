using Social.Application.Common;

namespace Social.Application.DTOs;

public enum FeedType
{
    Following = 0,
    Discovery = 1,
}

/// <summary>
/// Cursor-based feed query. <see cref="Cursor"/> is opaque base64 compound cursor (or legacy ISO-8601).
/// </summary>
public class FeedCursorQuery
{
    /// <summary>Opaque cursor from previous page; omit for the first page.</summary>
    public string? Cursor { get; set; }

    public int Limit { get; set; } = 20;

    public FeedType Type { get; set; } = FeedType.Following;

    /// <summary>When provided, each returned post will include <c>IsLikedByMe</c> for this user.</summary>
    public Guid? ViewerUserId { get; set; }
}

public sealed class CursorFeedResult<T>
{
    public required IReadOnlyList<T> Items { get; init; }
    public string? NextCursor { get; init; }
    public bool HasMore { get; init; }
}
