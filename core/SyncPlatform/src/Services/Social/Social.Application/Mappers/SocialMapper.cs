using Social.Application.DTOs;
using Social.Domain.Helpers;
using Social.Domain.Models;

namespace Social.Application.Mappers;

public static class SocialMapper
{
    public static PostDto ToDto(this Post entity, bool isLikedByMe = false) =>
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
            IsLikedByMe = isLikedByMe,
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

    public static CommunityChallengeDto ToDto(this CommunityChallenge entity)
    {
        var location = GeoLocationMapping.FromGeoJsonPoint(entity.Location);

        return new CommunityChallengeDto
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
            CreatorId = entity.CreatorId,
            Title = entity.Title,
            Description = entity.Description,
            RegistrationDeadline = entity.RegistrationDeadline,
            StartDate = entity.StartDate,
            EndDate = entity.EndDate,
            GoalType = entity.GoalType,
            TargetValue = entity.TargetValue,
            PointRewards = entity.PointRewards,
            Gifts = entity.Gifts ?? [],
            ParticipantCount = entity.ParticipantCount,
            Address = entity.Address,
            Location = location is null
                ? null
                : new GeoLocationDto
                {
                    Latitude = location.Value.Latitude,
                    Longitude = location.Value.Longitude,
                },
            Status = entity.Status,
        };
    }

    public static ChallengeParticipantDto ToDto(this ChallengeParticipant entity) =>
        new()
        {
            UserId = entity.UserId,
            Status = entity.Status,
            JoinedAt = entity.JoinedAt,
            CompletedAt = entity.CompletedAt,
            IsActive = entity.IsActive,
        };

    public static NearbyCommunityChallengeDto ToNearbyDto(this CommunityChallengeDto dto) =>
        new()
        {
            Id = dto.Id,
            CreatedAt = dto.CreatedAt,
            UpdatedAt = dto.UpdatedAt,
            CreatorId = dto.CreatorId,
            Title = dto.Title,
            Description = dto.Description,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            GoalType = dto.GoalType,
            TargetValue = dto.TargetValue,
            PointRewards = dto.PointRewards,
            Gifts = dto.Gifts,
            ParticipantCount = dto.ParticipantCount,
            Address = dto.Address,
            Location = dto.Location,
            Status = dto.Status,
        };

    public static StoryDto ToDto(this Story entity, bool isLikedByMe = false) =>
        new()
        {
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            ExpiresAt = entity.ExpiresAt,
            AuthorId = entity.AuthorId,
            AuthorSnapshot = new AuthorSnapshotDto
            {
                FullName = entity.AuthorSnapshot.FullName,
                AvatarUrl = entity.AuthorSnapshot.AvatarUrl,
            },
            MediaUrl = entity.MediaUrl,
            MediaType = entity.MediaType,
            Caption = entity.Caption,
            ViewCount = entity.ViewCount,
            LikeCount = entity.LikeCount,
            Privacy = entity.Privacy,
            IsLikedByMe = isLikedByMe,
        };

    public static UserFollowDto ToDto(this UserFollow entity) =>
        new()
        {
            Id = entity.Id,
            FollowerId = entity.FollowerId,
            FolloweeId = entity.FolloweeId,
            Status = entity.Status,
            FollowedAt = entity.FollowedAt,
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
            ParentCommentId = entity.ParentCommentId,
        };

    public static BlogDto ToDto(this Blog entity, bool isLikedByMe = false) =>
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
            Title = entity.Title,
            Slug = entity.Slug,
            CoverImageUrl = entity.CoverImageUrl,
            MediaUrls = entity.MediaUrls ?? [],
            Content = entity.Content,
            Tags = entity.Tags,
            Status = entity.Status,
            PublishedAt = entity.PublishedAt,
            LikeCount = entity.LikeCount,
            ShareCount = entity.ShareCount,
            IsLikedByMe = isLikedByMe,
        };
}
