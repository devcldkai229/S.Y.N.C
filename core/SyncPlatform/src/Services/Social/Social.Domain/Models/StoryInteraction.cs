using Social.Domain.Enums;

namespace Social.Domain.Models;

/// <summary>
/// Engagement on a story (likes). Separate from post <see cref="Interaction"/>.
/// </summary>
public class StoryInteraction : BaseMongoEntity
{
    public Guid StoryId { get; set; }

    public Guid UserId { get; set; }

    public InteractionType InteractionType { get; set; }
}
