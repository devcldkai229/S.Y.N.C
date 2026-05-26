namespace Social.Domain.Models;

/// <summary>
/// Embedded counters on Post for fast feed queries.
/// </summary>
public class PostMetrics
{
    public int LikeCount { get; set; }

    public int CommentCount { get; set; }

    public int ShareCount { get; set; }
}
