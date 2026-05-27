namespace Social.Application.DTOs;

/// <summary>
/// Cursor-based feed query. <see cref="Cursor"/> is the <c>CreatedAt</c> of the last post on the previous page.
/// </summary>
public class FeedCursorQuery
{
    /// <summary>ISO-8601 CreatedAt of the oldest item from the previous page; omit for the first page.</summary>
    public DateTimeOffset? Cursor { get; set; }

    public int Limit { get; set; } = 20;
}
