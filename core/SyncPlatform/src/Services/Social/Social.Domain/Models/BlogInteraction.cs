using Social.Domain.Enums;

namespace Social.Domain.Models;

/// <summary>
/// Like/share engagement on a blog post.
/// </summary>
public class BlogInteraction : BaseMongoEntity
{
    public Guid BlogId { get; set; }

    public Guid UserId { get; set; }

    public InteractionType InteractionType { get; set; }
}
