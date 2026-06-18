using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IInteractionService
{
    Task<InteractionDto> AddAsync(
        Guid userId,
        Guid postId,
        CreateInteractionDto dto,
        CancellationToken cancellationToken = default);
}
