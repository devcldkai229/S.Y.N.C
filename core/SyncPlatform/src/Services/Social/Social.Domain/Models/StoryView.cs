namespace Social.Domain.Models;

/// <summary>
/// Records a unique story view per viewer (used for view notifications).
/// </summary>
public class StoryView : BaseMongoEntity
{
    public Guid StoryId { get; set; }

    public Guid ViewerId { get; set; }

    public DateTimeOffset ViewedAt { get; set; } = DateTimeOffset.UtcNow;
}
