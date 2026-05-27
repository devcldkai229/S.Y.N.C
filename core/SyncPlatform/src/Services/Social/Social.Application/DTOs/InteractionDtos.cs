using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class InteractionDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public Guid PostId { get; set; }
    public Guid UserId { get; set; }
    public InteractionType InteractionType { get; set; }
}

public class CreateInteractionDto
{
    public InteractionType InteractionType { get; set; }
}
