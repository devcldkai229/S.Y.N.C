using Social.Application.DTOs;
using Social.Domain.Models;

namespace Social.Application.Mappers;

public static class SocialMapper
{
    public static PostDto ToDto(this Post entity) =>
        new()
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
            AuthorId = entity.AuthorId,
            AuthorSnapshot = new AuthorSnapshotDto
            {
                FullName = entity.AuthorSnapshot.FullName,
                AvatarUrl = entity.AuthorSnapshot.AvatarUrl,
            },
            PostType = entity.PostType,
            Content = entity.Content,
            MediaUrls = entity.MediaUrls,
            ReferenceId = entity.ReferenceId,
            Metrics = new PostMetricsDto
            {
                LikeCount = entity.Metrics.LikeCount,
                CommentCount = entity.Metrics.CommentCount,
                ShareCount = entity.Metrics.ShareCount,
            },
            IsPublic = entity.IsPublic,
            ShareCode = entity.ShareCode,
        };

    public static InteractionDto ToDto(this Interaction entity) =>
        new()
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            PostId = entity.PostId,
            UserId = entity.UserId,
            InteractionType = entity.InteractionType,
        };

    public static CommunityChallengeDto ToDto(this CommunityChallenge entity) =>
        new()
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
            CreatorId = entity.CreatorId,
            Title = entity.Title,
            Description = entity.Description,
            StartDate = entity.StartDate,
            EndDate = entity.EndDate,
            GoalType = entity.GoalType,
            TargetValue = entity.TargetValue,
            ParticipantCount = entity.ParticipantCount,
            Status = entity.Status,
        };

    public static CommentDto ToDto(this Comment entity) =>
        new()
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            PostId = entity.PostId,
            UserId = entity.UserId,
            Content = entity.Content,
            AuthorSnapshot = entity.AuthorSnapshot is null
                ? null
                : new AuthorSnapshotDto
                {
                    FullName = entity.AuthorSnapshot.FullName,
                    AvatarUrl = entity.AuthorSnapshot.AvatarUrl,
                },
        };
}
