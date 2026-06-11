using Social.Domain.Enums;

namespace Social.Domain.Models;

public class Interaction : BaseMongoEntity
{
    public Guid PostId { get; set; }

    public Guid UserId { get; set; }

    public InteractionType InteractionType { get; set; }
}
