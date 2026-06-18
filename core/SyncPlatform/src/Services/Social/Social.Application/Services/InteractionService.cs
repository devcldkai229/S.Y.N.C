using Social.Application.Clients;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class InteractionService : IInteractionService
{
    private readonly IInteractionRepository _interactions;
    private readonly IPostRepository _posts;
    private readonly ISocialNotificationClient _notifications;

    public InteractionService(
        IInteractionRepository interactions,
        IPostRepository posts,
        ISocialNotificationClient notifications)
    {
        _interactions = interactions;
        _posts = posts;
        _notifications = notifications;
    }

    public async Task<InteractionDto> AddAsync(
        Guid userId,
        Guid postId,
        CreateInteractionDto dto,
        CancellationToken cancellationToken = default)
    {
        if (!await _posts.ExistsAsync(postId, cancellationToken))
            throw new NotFoundException($"Post {postId} was not found.");

        var existing = await _interactions.GetAsync(postId, userId, dto.InteractionType, cancellationToken);
        if (existing is not null)
            throw new ConflictException("You have already performed this interaction on the post.");

        var interaction = new Interaction
        {
            PostId = postId,
            UserId = userId,
            InteractionType = dto.InteractionType,
        };

        var created = await _interactions.TryCreateAsync(interaction, cancellationToken);
        if (!created)
            throw new ConflictException("You have already performed this interaction on the post.");

        await _posts.IncrementMetricAsync(
            postId,
            metrics =>
            {
                switch (dto.InteractionType)
                {
                    case InteractionType.Like:
                        metrics.LikeCount++;
                        break;
                    case InteractionType.Share:
                        metrics.ShareCount++;
                        break;
                }
            },
            cancellationToken);

        if (dto.InteractionType == InteractionType.Like)
        {
            var post = await _posts.GetByIdAsync(postId, cancellationToken);
            if (post is not null)
            {
                _ = _notifications.NotifyPostLikedAsync(userId, post.AuthorId, postId, cancellationToken);
            }
        }

        return interaction.ToDto();
    }
}
